require 'net/http'
require 'open-uri'
require 'openssl'
require 'workspace_helper'


describe "TsuruEndToEnd" do
  before(:all) do
    @tsuru_api_host = RSpec.configuration.target_api_host || raise("You must set 'TARGET_API_HOST' env var")
    @tsuru_api_url = "https://#{@tsuru_api_host}"
    @tsuru_api_url_insecure = "http://#{@tsuru_api_host}:8080"
  end

  describe "healthchecks" do
    let(:healthcheck_response) {
      Net::HTTP.get_response(URI.parse("#{@tsuru_api_url}/healthcheck/?check=all"))
    }

    it "should return each component as WORKING" do
      component_lines = healthcheck_response.body.split("\n")
      expect(component_lines.size).to be >= 3

      component_lines.each do |component_line|
        expect(component_line).to match(%r{:\sWORKING\s})
      end
    end

    it "should return status code of 200 to indicate all components are healthy" do
      expect(healthcheck_response.code.to_i).to eq(200)
    end
  end

  context "deploying an application" do
    before(:all) do

      @workspace = WorkSpace.new()
      @workspace.tsuru_command.target_add("ci", @tsuru_api_url)
      @workspace.tsuru_command.target_add("ci-insecure", @tsuru_api_url_insecure)

      @tsuru_user = RSpec.configuration.tsuru_user || raise("You must set 'TSURU_USER' env var")
      @tsuru_pass = RSpec.configuration.tsuru_pass || raise("You must set 'TSURU_PASS' env var")

      # Clone the sample app and setup Git
      @sampleapp_name = 'sampleapp' + Time.now.to_i.to_s
      @sampleapp_path = File.join(@workspace.tsuru_home, @sampleapp_name)

      @git_command = @workspace.create_git_command(@sampleapp_path)
      @git_command.clone("https://github.com/alphagov/flask-sqlalchemy-postgres-heroku-example.git")

      # Generate a random DB instance. postgresql truncates this name
      # to create objects in postgres, so we need to keep the most variable
      # part in the first characters.
      @sampleapp_db_instance = 'tst' + Time.now.to_i.to_s.reverse

    end

    after(:all) do
      # Remove previous state if needed.
      @workspace.tsuru_command.key_remove('rspec')
      # Remove the app. Wait for the unlock if needed
      retries=25
      begin
        @workspace.tsuru_command.app_remove(@sampleapp_name)
        expect(@workspace.tsuru_command.stderr).to_not match /App locked by/
      rescue RSpec::Expectations::ExpectationNotMetError
        sleep 5
        retry if (retries -= 1) > 0
        @workspace.tsuru_command.app_unlock(@sampleapp_name)
        @workspace.tsuru_command.app_remove(@sampleapp_name)
      end
      retries=25
      begin
        sleep 1
        @workspace.tsuru_command.service_remove(@sampleapp_db_instance)
        expect(@workspace.tsuru_command.stderr).to_not match /This service instance is bound to at least one app/
      rescue RSpec::Expectations::ExpectationNotMetError
        retry if (retries -= 1) > 0
      end
      @workspace.clean
    end

    it "should not be able to login via HTTP" do
      @workspace.tsuru_command.target_set("ci-insecure")
      @workspace.tsuru_command.login(@tsuru_user, @tsuru_pass)
      expect(@workspace.tsuru_command.exit_status).not_to eql 0
    end

    it "should be able to login via HTTPS" do
      @workspace.tsuru_command.target_set("ci")
      @workspace.tsuru_command.login(@tsuru_user, @tsuru_pass)
      expect(@workspace.tsuru_command.exit_status).to eql 0
    end

    it "should be able to add the ssh key" do
      @workspace.tsuru_command.key_add('rspec', @workspace.ssh_id_rsa_pub_path)
      expect(@workspace.tsuru_command.exit_status).to eql 0
      expect(@workspace.tsuru_command.stdout).to match /Key .* successfully added!/
    end

    it "should be able to create an application" do
      @workspace.tsuru_command.app_create(@sampleapp_name, 'python')
      expect(@workspace.tsuru_command.exit_status).to eql 0
      expect(@workspace.tsuru_command.stdout).to match /App .* has been created/
    end

    it "should be able to create a service" do
      @workspace.tsuru_command.service_add('postgresql', @sampleapp_db_instance, 'shared')
      expect(@workspace.tsuru_command.exit_status).to eql 0
      expect(@workspace.tsuru_command.stdout).to match /Service successfully added/
    end

    it "should be able to bind a service to an app" do
      @workspace.tsuru_command.service_bind(@sampleapp_db_instance, @sampleapp_name)
      expect(@workspace.tsuru_command.exit_status).to eql 0
      expect(@workspace.tsuru_command.stdout).to match /Instance .* is now bound to the app .*/
    end

    it "should be able to push the application" do
      git_url = @workspace.tsuru_command.get_app_repository(@sampleapp_name)
      expect(git_url).not_to be_nil
      @git_command.push(git_url)
      expect(@git_command.exit_status).to eql 0
    end

    it "should be able to connect to the applitation via HTTPS" do
      sampleapp_address = @workspace.tsuru_command.get_app_address(@sampleapp_name)
      response = URI.parse("https://#{sampleapp_address}/").open({ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
      expect(response.status).to eq(["200", "OK"])
    end

    it "should get log output in 3 seconds" do
      sampleapp_address = @workspace.tsuru_command.get_app_address(@sampleapp_name)
      query = "my_special_query_" + Time.now.to_i.to_s
      @workspace.tsuru_command.tail_app_logs(@sampleapp_name)
      sleep 1
      begin
        response = URI.parse("https://#{sampleapp_address}/" + query).open({ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
      rescue
        ()
      end
      sleep 3
      @workspace.tsuru_command.ctrl_c()
      @workspace.tsuru_command.wait()
      expect(@workspace.tsuru_command.stdout).to include query
    end

    it "should be able to connect to the applitation via HTTPS with a valid cert" do
      pending "We don't have a certificate for this :)"
      sampleapp_address = @workspace.tsuru_command.get_app_address(@sampleapp_name)
      response = URI.parse("https://#{sampleapp_address}/").open()
      expect(response.status).to eq(["200", "OK"])
    end

    it "should be able to unbind and bind a service to an app" do
      pending "There is already a bug filed: https://github.com/tsuru/postgres-api/issues/1"
      @workspace.tsuru_command.service_unbind(@sampleapp_db_instance, @sampleapp_name)
      expect(@workspace.tsuru_command.exit_status).to eql 0
      @workspace.tsuru_command.service_bind(@sampleapp_db_instance, @sampleapp_name)
      expect(@workspace.tsuru_command.exit_status).to eql 0
      expect(@workspace.tsuru_command.stdout).to match /Instance .* is now bound to the app .*/
    end

  end
end



