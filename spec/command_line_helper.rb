require 'open3'

# Generic wrapper around the CommandLine
class CommandLineHelper
  attr_reader :exit_status, :stderr, :stdout, :last_command, :env

  def initialize(env = {})
    @env = env
  end

  protected

  def execute_helper(*cmd)
    @exit_status=nil
    @stderr=nil
    @stdout=nil

    Open3.popen3(@env, *cmd) do |stdin, out, err, wait_thread|
      # Allow additional preprocessing of the system call if the caller passes a block
      yield(stdin, out, err, wait_thread) if block_given?

      @stdout = out.readlines().join
      @stderr = err.readlines().join
      [stdin, out, err].each{|stream| stream.close() if not stream.closed? }
      @exit_status = wait_thread.value.to_i
    end
    return @exit_status == 0
  end
end