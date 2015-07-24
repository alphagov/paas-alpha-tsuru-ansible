require 'open3'

# Generic wrapper around the CommandLine
class CommandLineHelper
  attr_reader :exit_status, :stderr, :stdout, :last_command, :env

  def initialize(env = {}, options = {})
    @env = env
    @options = options
  end

  def wait()
    @tout.join if @tout
    @terr.join if @terr
    if @wait_thread
      # Return code can be the the signal number if killed with signal
      # or exit value shifted 8 bits if exited normally
      if @wait_thread.value.signaled?
        @exit_status = @wait_thread.value.to_i + 128
      else
        @exit_status = @wait_thread.value.to_i >> 8
      end
    end
    self
  end

  def ctrl_c()
    Process.kill("TERM", @wait_thread.pid)
  end

  protected

  def execute_helper_async(*cmd)
    @exit_status=nil
    @stderr = ''
    @stdout = ''

    $stdout.puts "Executing: #{@env.map { |k,v| "#{k}='#{v}'" }.join(' ')} #{cmd.join(' ')}" if @options[:verbose]

    @in_fd, @out_fd, @err_fd, @wait_thread = Open3.popen3(@env, *cmd)

    # Print standard out end error as they receive content
    @tout = Thread.new do
      @out_fd.each {|l|
        $stdout.puts "stdout: #{l}" if @options[:verbose]
        @stdout << l
      }
    end
    @terr = Thread.new do
      @err_fd.each {|l|
        $stderr.puts "stderr: #{l}" if @options[:verbose]
        @stderr << l
      }
    end
  end

  def execute_helper(*cmd)
    execute_helper_async(*cmd)

    # Allow additional preprocessing of the system call if the caller passes a block
    yield(@in_fd, @out_fd, @err_fd, @wait_thread) if block_given?

    self.wait

    $stdout.puts "Exit code: #{@exit_status}" if @options[:verbose]
    return @exit_status == 0
  end

end
