require 'serverspec'
require 'highline/import' # for ask function
require 'net/ssh/proxy/command'

set :backend, :ssh
set :disable_sudo, true

# Load the host
host = ENV['TARGET_HOST']

# Load the configuration for this host
# It will scan the default files plus 'ssh.config'
options = Net::SSH::Config.for(host, Net::SSH::Config.default_files << './ssh.config')

options[:user] ||= ENV['TARGET_USER']
options[:port] ||= ENV['TARGET_PORT']
options[:keys] ||= ENV['TARGET_PRIVATE_KEY']

if ENV['TARGET_PROXY']
  proxy = Net::SSH::Proxy::Command.new("ssh #{ENV['TARGET_PROXY']} nc %h %p")
  options[:proxy] = proxy
end

# Load the host
set :host,  options[:host_name] || host

set :ssh_options, options

# Set environment variables
set :env, :LANG => 'C', :LC_MESSAGES => 'C'

