require 'minigit'

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

# Minigit does not capture the stderr. This small class overrides the
# system call to redirect stderr to stdout
class MiniGitStdErrCapturing < MiniGit::Capturing
  def system(*args)
    `#{Shellwords.join(args)} 2>&1`
  end
end


