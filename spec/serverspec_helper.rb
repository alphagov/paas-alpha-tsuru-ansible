require 'serverspec'

set :backend, :ssh
#set :ssh_options, { :user => ubuntu }
set :disable_sudo, true

# Load the host
host = ENV['TARGET_HOST']

# Load the configuration for this host
# It will scan the default files plus 'ssh.config'
#options = Net::SSH::Config.for(host, Net::SSH::Config.default_files << './ssh.config')
options = Net::SSH::Config.for(host, [ './ssh.config' ])
puts options
set :ssh_options, options

# Load the host
set :host,  options[:host_name] || host

# Set environment variables
set :env, :LANG => 'C', :LC_MESSAGES => 'C'

