require 'rake'
require 'rspec/core/rake_task'

# Hardcoded set of machines, for the time being.
# Needs to be implemented to consume the IaaS information
def get_hosts()
  [
    {
      :name => "ci-tsuru-api-0",
      :ssh_host => "10.128.11.215",
      :ssh_port => nil,
      :ssh_user => "ubuntu",
      :ssh_proxy => "ec2-user@ci-nat.tsuru.paas.alphagov.co.uk",
      :ssh_key => '~/.ssh/id_rsa'
    },
    {
      :name => "ci-tsuru-docker-0",
      :ssh_host => "10.128.13.205",
      :ssh_port => 22,
      :ssh_user => "ubuntu",
      :ssh_key => '~/.ssh/id_rsa'
    },
  ]
end

def get_hosts_and_roles()
  # Hardcoded mapping host => role
  global_roles = Hash.new
  get_hosts().map { |host|
    roles = []
    if m = /.*-(tsuru-.*)(-[0-9])/.match(host[:name])
      roles = roles << m[1]
    end
    ret = host.clone()
    ret[:roles] = roles
    ret
  }
end

# Generates the tasks dynamically for each server and role
namespace :integration do
  get_hosts_and_roles().each do |host|
    host[:roles].each do |role|
      namespace role.to_sym do
        desc "Run serverspec for #{role} on #{host[:name]}"
        RSpec::Core::RakeTask.new("#{role}_#{host[:name]}") do |t|
          puts "Run serverspec for #{role} to #{host[:name]}"
          ENV['TARGET_HOST'] = host[:ssh_host]
          ENV['TARGET_PORT'] = host[:ssh_port].to_s if host[:ssh_port]
          ENV['TARGET_PROXY'] = host[:ssh_proxy]
          ENV['TARGET_PRIVATE_KEY'] = host[:ssh_key]
          ENV['TARGET_USER'] = host[:ssh_user]
          puts ENV['TARGET_HOST']
          t.pattern = "spec/integration/#{role}/*_spec.rb"
        end
      end
    end
  end
  task :all do
    Rake.application.in_namespace(:integration){|x| x.tasks.each{|t| t.invoke}}
  end
end

namespace :endtoend do
  RSpec::Core::RakeTask.new(:all) do |t|
    t.pattern = "spec/endtoend/*_spec.rb"
  end
end

# Run all tasks
task :default => [ "integration:all", "endtoend:all" ]

