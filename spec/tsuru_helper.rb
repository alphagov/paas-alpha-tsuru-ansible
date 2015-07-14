require 'tempfile'
require 'fileutils'
require 'command_line_helper'

RSpec.configure do |c|
  c.add_setting :debug_commands, :default => false

  c.add_setting :deploy_env, :default => ENV['DEPLOY_ENV'] || 'ci'

  c.add_setting :target_api_host, :default => ENV['TARGET_API_HOST']

  c.add_setting :tsuru_user, :default => ENV['TSURU_USER']
  c.add_setting :tsuru_pass, :default => ENV['TSURU_PASS']
  c.add_setting :verbose, :default => (ENV['VERBOSE'] and ENV['VERBOSE'].downcase == 'true')

  puts "Running test against: '#{RSpec.configuration.target_api_host}'"
end

# Ruby 2.2.2 does not provide mktmpdir. Use Tempfile instead
class Tempdir < Tempfile
  def initialize(basename)
    super
    File.delete(self.path)
    Dir.mkdir(self.path)
  end
  def rmrf
    FileUtils.rm_rf(@tmpname)
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

# Wrapper adount the TsuruCommandLine
class TsuruCommandLine < CommandLineHelper

  def target_add(target_label, target_url)
    execute_helper('tsuru', 'target-add', target_label, target_url)
  end

  def target_set(target_label)
    execute_helper('tsuru', 'target-set', target_label)
  end

  def app_create(app_name, platform)
    execute_helper('tsuru', 'app-create', app_name, platform, '-t', 'admin')
  end

  def app_remove(app_name)
    execute_helper('tsuru', 'app-remove', '-a', app_name, '-y')
  end

  def key_add(ssh_key_name, ssh_key_path)
    execute_helper('tsuru', 'key-add', ssh_key_name, ssh_key_path)
  end

  def key_remove(ssh_key_name)
    execute_helper('tsuru', 'key-remove', ssh_key_name, '-y')
  end

  def service_add(service_name, service_instance_name, plan)
    execute_helper('tsuru', 'service-add', service_name, service_instance_name, plan, '-t', 'admin')
  end

  def service_remove(service_instance_name)
    execute_helper('tsuru', 'service-remove', service_instance_name, '-y')
  end

  def service_bind(service_instance_name, app_name)
    execute_helper('tsuru', 'service-bind', service_instance_name, '-a', app_name)
  end

  def service_unbind(service_instance_name, app_name)
    execute_helper('tsuru', 'service-unbind', service_instance_name, '-a', app_name)
  end

  def get_app_repository(app_name)
    execute_helper('tsuru', 'app-info', '-a', app_name)
    (m = /^Repository: (.*)$/.match(@stdout)) ? m[1] : nil
  end

  def tail_app_logs(app_name)
    execute_helper_async('tsuru','app-log','-a', app_name, '-f')
  end

  def get_app_address(app_name)
    execute_helper('tsuru', 'app-info', '-a', app_name)
    (m = /^Address: (.*)$/.match(@stdout)) ? m[1] : nil
  end

  def login(login, pass)
    execute_helper('tsuru', 'login', login) do |stdin, out, err, wait_thread|
      stdin.write(pass + "\n")
      stdin.flush()
      stdin.close()
    end
  end

end
