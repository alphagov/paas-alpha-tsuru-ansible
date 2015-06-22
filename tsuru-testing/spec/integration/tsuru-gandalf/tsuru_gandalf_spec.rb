require 'serverspec_helper'

describe file('/home/git/.bash_profile') do
  it "should use a DNS to connect to the api" do
    should contain(/export TSURU_HOST=https:\/\/.*-api/)
  end
end

