require 'net/http'
require 'open-uri'
require 'openssl'
require 'workspace_helper'


describe "Integration" do
  before(:all) {
    @workspace = WorkSpace.new()
    @tsuru_api_host = RSpec.configuration.target_api_host || raise("You must set 'TARGET_API_HOST' env var")
    @tsuru_user = RSpec.configuration.tsuru_user || raise("You must set 'TSURU_USER' env var")
    @tsuru_pass = RSpec.configuration.tsuru_pass || raise("You must set 'TSURU_PASS' env var")
    @tsuru_api_url = "https://#{@tsuru_api_host}"
    @workspace.do_login(@tsuru_api_url, @tsuru_user, @tsuru_pass)
  }
  after(:all) do
    @workspace.clean
  end

  context "checking timeout while deploying" do
    before(:all) do
      @sampleapp_name = 'sampleapp' + Time.now.to_i.to_s
      @sampleapp_path = File.join(@workspace.tsuru_home, @sampleapp_name)
      FileUtils.mkdir(@sampleapp_path)
      FileUtils.touch(File.join(@sampleapp_path, 'file.txt'))

      @sampleplatform_name = 'sampleplatform' + Time.now.to_i.to_s

      @git_command = @workspace.create_git_command(@sampleapp_path)
      @git_command.init()
      @git_command.config_name_mail("John Smith", "john.smith@example.com")
      @git_command.add("file.txt")
      @git_command.commit("a commit")
    end

    after(:all) do
      # Remove the application. Wait for the unlock if needed
      retries=5
      begin
        @workspace.tsuru_command.app_remove(@sampleapp_name)
        expect(@workspace.tsuru_command.stderr).to_not match /App locked by/
      rescue RSpec::Expectations::ExpectationNotMetError
        sleep 5
        retry if (retries -= 1) > 0
        @workspace.tsuru_command.app_unlock(@sampleapp_name)
        @workspace.tsuru_command.app_remove(@sampleapp_name)
      end
      # Remove the platform
      retries=5
      begin
        @workspace.tsuru_command.platform_remove(@sampleplatform_name)
        expect(@workspace.tsuru_command.stderr).to_not match /Platform has apps/
      rescue RSpec::Expectations::ExpectationNotMetError
        # Wait to the app to get deleted, we found that tsuru
        # takes some seconds to actually get the application removed.
        sleep 5
        retry if (retries -= 1) > 0
      end
    end

    it "should be able to deploy a platform with a delay in tsuru_unit_agent" do
      @workspace.tsuru_command.platform_add(@sampleplatform_name, 'https://raw.githubusercontent.com/alphagov/tsuru-ansible/master/spec/test_platforms/delay_unit_platform/Dockerfile')
      expect(@workspace.tsuru_command.exit_status).to eql 0
      expect(@workspace.tsuru_command.stdout).to match /Platform successfully added/
    end

    it "should be able to create an application using the delay platform" do
      @workspace.tsuru_command.app_create(@sampleapp_name, @sampleplatform_name)
      expect(@workspace.tsuru_command.exit_status).to eql 0
      expect(@workspace.tsuru_command.stdout).to match /App .* has been created/
    end

    it "Should be able to push the application and not timeout" do
      git_url = @workspace.tsuru_command.get_app_repository(@sampleapp_name)
      expect(git_url).not_to be_nil
      @git_command.push(git_url)
      expect(@git_command.exit_status).to eql 0
    end

  end
end




