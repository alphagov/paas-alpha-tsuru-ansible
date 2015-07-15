require 'command_line_helper'

class SshHelper
  # Create our own SSH key
  def self.generate_key(path)
    FileUtils.mkdir_p(File.dirname(path))
    system("ssh-keygen -f #{path} -q -N '' ")
  end

  # Generate some custom configuration for SSH
  # WARNING: overrides the file
  def self.write_config(config_path, config)
    File.open(config_path, 'w') { |f|
      f.write("Host *\n")
      config.each { |k,v|
        f.write("\t#{k} #{v}\n")
      }
    }
  end

  # Older versions of git < 2.3 do not allow use the GIT_SSH_COMMAND variable
  # but only specify the ssh binary with GIT_SSH. Because that, in order to
  # specify the configuration file we need to create a wrapper
  def self.write_ssh_wrapper(wrapper_path, config_path)
    File.open(wrapper_path, 'w') { |f|
      f.write("""
#!/bin/bash
ssh -F #{config_path} $@
""")
    }
    File.chmod(0755, wrapper_path)
  end
end


class GitCommandLine < CommandLineHelper

  def initialize(path, env = {}, options = {})
    super(env, options)
    @path = path
  end

  def clone(url)
    execute_helper('git', 'clone', url, @path)
  end

  def init()
    execute_helper('git', 'init', { :chdir => @path })
  end

  def config_name_mail(name, mail)
    execute_helper('git', 'config', 'user.name', name, { :chdir => @path })
    execute_helper('git', 'config', 'user.email', mail, { :chdir => @path })
  end

  def add(*cmd)
    execute_helper('git', 'add', *cmd, { :chdir => @path })
  end

  def commit(msg)
    execute_helper('git', 'commit', '-m', msg, { :chdir => @path })
  end

  def push(remote = 'origin', local_branch = 'master', remote_branch = 'master')
    execute_helper('git', 'push', remote, "#{local_branch}:#{remote_branch}", { :chdir => @path })
  end

end
