require 'git_helper'
require 'tsuru_helper'

class WorkSpace
  attr_accessor :tsuru_home, :tsuru_user, :tsuru_pass, :ssh_id_rsa_pub_path
  attr_accessor :tsuru_command

  def clean()
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

  def initialize()
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
