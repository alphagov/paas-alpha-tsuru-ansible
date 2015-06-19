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
end

class GitCommandLine < CommandLineHelper

  def initialize(path, env = {})
    @env = env
    @path = path
  end

  def clone(url)
    execute_helper('git', 'clone', url, @path)
  end

  def push(remote = 'origin', local_branch = 'master', remote_branch = 'master')
    execute_helper('git', 'push', remote, "#{local_branch}:#{remote_branch}", { :chdir => @path })
  end

end
