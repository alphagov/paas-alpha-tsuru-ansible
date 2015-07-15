require 'git_helper'
require 'tsuru_helper'

class WorkSpace
  attr_accessor :tsuru_home, :tsuru_user, :tsuru_pass, :ssh_id_rsa_pub_path
  attr_accessor :tsuru_command
  attr_accessor :has_login

  def clean()
      # Remove previous state if needed
      @tsuru_command.key_remove('default_key') if @has_login
      @tsuru_home.rmrf
  end

  def create_git_command(path)
      @git_command = GitCommandLine.new(path,
        {
          'HOME' => @tsuru_home.path,
          'GIT_SSH' => @ssh_wrapper_path
        },
        { :verbose => RSpec.configuration.verbose }
      )
  end

  def do_login(tsuru_api_url, tsuru_user, tsuru_pass)
      @tsuru_command.target_add("api", tsuru_api_url)
      @tsuru_command.target_set("api")
      @tsuru_command.login(tsuru_user, tsuru_pass)
      raise "Failed login: #{@tsuru_command.stderr}" if @tsuru_command.exit_status != 0
      @tsuru_command.key_add('default_key', @ssh_id_rsa_pub_path)
      raise "Failed key-add: #{@tsuru_command.stderr}" if @tsuru_command.exit_status != 0
      @has_login = true
  end

  def initialize()
      @has_login = false
      @tsuru_home = Tempdir.new('tsuru-command')
      @tsuru_command = TsuruCommandLine.new(
        { 'HOME' => @tsuru_home.path },
        { :verbose => RSpec.configuration.verbose }
      )

      # Generate the ssh key and setup ssh
      @ssh_id_rsa_path = File.join(@tsuru_home, '.ssh', 'id_rsa')
      @ssh_id_rsa_pub_path = File.join(@tsuru_home, '.ssh', 'id_rsa.pub')
      @ssh_config_file = File.join(@tsuru_home, '.ssh', 'config')
      @ssh_wrapper_path = File.join(@tsuru_home, 'ssh-wrapper')
      SshHelper.generate_key(@ssh_id_rsa_path)
      SshHelper.write_config(
        @ssh_config_file,
        {
        "StrictHostKeyChecking" => "no",
        "IdentityFile" => @ssh_id_rsa_path,
        }
      )
      SshHelper.write_ssh_wrapper(@ssh_wrapper_path, @ssh_config_file)

  end
end
