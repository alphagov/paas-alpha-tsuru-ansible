require 'serverspec_helper'

describe command('ls /tmp') do
  its(:exit_status) { should eq 0 }
end

