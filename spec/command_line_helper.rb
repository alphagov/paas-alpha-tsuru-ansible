require 'open3'

# Generic wrapper around the CommandLine
class CommandLineHelper
  attr_reader :exit_status, :stderr, :stdout, :last_command, :env

  def initialize(env = {}, options = {})
    @env = env
    @options = options
  end

  protected

  def execute_helper(*cmd)
    @exit_status=nil
    @stderr = ''
    @stdout = ''

    $stdout.puts "Executing: #{@env.map { |k,v| "#{k}='#{v}'" }.join(' ')} #{cmd.join(' ')}" if @options[:verbose]

    Open3.popen3(@env, *cmd) do |stdin, out, err, wait_thread|
      # Allow additional preprocessing of the system call if the caller passes a block
      yield(stdin, out, err, wait_thread) if block_given?

      # Print standard out end error as they receive content
      tout = Thread.new do
        out.each {|l|
          $stdout.puts "stdout: #{l}" if @options[:verbose]
          @stdout << l
        }
      end
      terr = Thread.new do
        err.each {|l|
          $stderr.puts "stderr: #{l}" if @options[:verbose]
          @stderr << l
        }
      end

      tout.join
      terr.join
      # [stdin, out, err].each{|stream| stream.close() if not stream.closed? }
      @exit_status = wait_thread.value.to_i >> 8
    end

    $stdout.puts "Exit code: #{@exit_status}"
    return @exit_status == 0
  end
end