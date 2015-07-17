require 'rake'
require 'rspec/core/rake_task'

namespace :endtoend do
  RSpec::Core::RakeTask.new(:all) do |t|
    t.pattern = "spec/endtoend/*_spec.rb"
    t.verbose = false
  end
end

namespace :integration do
  RSpec::Core::RakeTask.new(:all) do |t|
    t.pattern = "spec/integration/*_spec.rb"
    t.verbose = false
  end
end


# Run all tasks
task :default => [ "endtoend:all", "integration:all" ]

