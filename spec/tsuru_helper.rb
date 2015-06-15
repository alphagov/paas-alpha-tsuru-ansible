require 'open3'
require 'tempfile'

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

    def login(login, pass)
      execute_helper('login', login) do |stdin, out, err, wait_thread|
        stdin.write(pass + "\n")
        stdin.flush()
        stdin.close()
      end
    end
    
    private
    
    def execute_helper(*cmd)
      puts @home.path
      @exit_status=nil
      @stderr=nil
      @stdout=nil
      cmd.insert(0,'tsuru')
      Open3.popen3({ 'HOME' => @home.path }, *cmd) do |stdin, out, err, wait_thread|
        # Allow additional preprocessing of the system call if the caller passes a block
        yield(stdin, out, err, wait_thread) if block_given?

        @stdout = out.gets("")
        puts @stdout
        @stderr = err.gets("")
        puts @stderr
        [stdin, out, err].each{|stream| stream.close() if not stream.closed? }
        @exit_status = wait_thread.value.to_i
      end
      return @exit_status == 0
    end
end
