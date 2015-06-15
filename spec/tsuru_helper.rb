require 'open3'
require 'tempfile'
require 'fileutils'


class Tempdir < Tempfile
  require 'tmpdir'
  def initialize(basename, tmpdir = Dir::tmpdir)
    super
    File.delete(self.path)
    Dir.mkdir(self.path)
  end
  def unlink # copied from tempfile.rb
    # keep this order for thread safeness
    begin
      Dir.unlink(@tmpname) if File.exist?(@tmpname)
      @@cleanlist.delete(@tmpname)
      @data = @tmpname = nil
      ObjectSpace.undefine_finalizer(self)
    rescue Errno::EACCES
      # may not be able to unlink on Windows; just ignore
    end
  end
end

class SshHelper
  def self.generate_key(path)
    FileUtils.mkdir_p(File.dirname(path))
    system("ssh-keygen -f #{path} -N ''")
  end

  def self.write_config(config_path, config)
    File.open(config_path, 'w') { |f|
      f.write("Host *\n")
      config.each { |k,v|
        f.write("\t#{k} #{v}\n")
      }
    }
  end
end

class TsuruCommandLine
  attr_reader :exit_status, :stderr, :stdout

  def initialize(home = ENV['HOME'])
    @home = home
  end

  def target_add(target_label, target_url)
    execute_helper('target-add', target_label, target_url)
  end

  def target_set(target_label)
    execute_helper('target-set', target_label)
  end

  def app_create(app_name, platform)
    execute_helper('app-create', app_name, platform)
  end

  def app_remove(app_name)
    execute_helper('app-remove', '-a', app_name, '-y')
  end

  def key_add(ssh_key_name, ssh_key_path)
    execute_helper('key-add', ssh_key_name, ssh_key_path)
  end

  def key_remove(ssh_key_name)
    execute_helper('key-remove', ssh_key_name, '-y')
  end

  def service_add(service_name, service_instance_name, plan)
    execute_helper('service-add', service_name, service_instance_name, plan)
  end

  def service_remove(service_instance_name)
    execute_helper('service-remove', service_instance_name, '-y')
  end

  def service_bind(service_instance_name, app_name)
    execute_helper('service-bind', service_instance_name, '-a', app_name)
  end

  def get_app_repository(app_name)
    execute_helper('app-info', '-a', app_name)
    (m = /^Repository: (.*)$/.match(@stdout)) ? m[1] : nil
  end
  def get_app_address(app_name)
    execute_helper('app-info', '-a', app_name)
    (m = /^Address: (.*)$/.match(@stdout)) ? m[1] : nil
  end

  def login(login, pass)
    execute_helper('login', login) do |stdin, out, err, wait_thread|
      stdin.write(pass + "\n")
      stdin.flush()
      stdin.close()
    end
  end

  private

  def execute_helper(*cmd)
    @exit_status=nil
    @stderr=nil
    @stdout=nil
    cmd.insert(0,'tsuru')
    Open3.popen3({ 'HOME' => @home.path }, *cmd) do |stdin, out, err, wait_thread|
      # Allow additional preprocessing of the system call if the caller passes a block
      yield(stdin, out, err, wait_thread) if block_given?

      @stdout = out.readlines().join
      @stderr = err.readlines().join
      [stdin, out, err].each{|stream| stream.close() if not stream.closed? }
      @exit_status = wait_thread.value.to_i

      # puts @stderr, @stdout TODO: print the output when the test fails
    end
    return @exit_status == 0
  end
end
