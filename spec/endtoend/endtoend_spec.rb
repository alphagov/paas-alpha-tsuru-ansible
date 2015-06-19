require 'open-uri'
require 'git_helper.rb'
require 'tsuru_helper.rb'


describe "TsuruEndToEnd" do
  context "deploying an application" do
    before(:all) do
      @tsuru_home = Tempdir.new('tsuru-command')
      @tsuru_command = TsuruCommandLine.new({ 'HOME' => @tsuru_home.path })

      @tsuru_api_url = "https://#{RSpec.configuration.target_api_host}"
      @tsuru_api_url_insecure = "http://#{RSpec.configuration.target_api_host}:8080"

      @tsuru_command.target_add("ci", @tsuru_api_url)
      @tsuru_command.target_add("ci-insecure", @tsuru_api_url_insecure)

      @tsuru_user = RSpec.configuration.tsuru_user || raise("You must set 'TSURU_USER' env var")
      @tsuru_pass = RSpec.configuration.tsuru_pass || raise("You must set 'TSURU_PASS' env var")

      # Clone the sample app and setup Git
      @sampleapp_name = 'sampleapp' + Time.now.to_i.to_s
      @sampleapp_path = File.join(@tsuru_home, @sampleapp_name)

      @git_command = GitCommandLine.new(@sampleapp_path, {
        'HOME' => @tsuru_home.path,
        'GIT_SSH_COMMAND' => "ssh -i #{@tsuru_home.path}/.ssh/id_rsa"
      })
      @git_command.clone("https://github.com/alphagov/flask-sqlalchemy-postgres-heroku-example.git")

      # Generate the ssh key and setup ssh
      @ssh_id_rsa_path = File.join(@tsuru_home, '.ssh', 'id_rsa')
      @ssh_id_rsa_pub_path = File.join(@tsuru_home, '.ssh', 'id_rsa.pub')
      SshHelper.generate_key(@ssh_id_rsa_path)
      SshHelper.write_config(File.join(@tsuru_home, '.ssh', 'config'),
                             { "StrictHostKeyChecking" => "no" } )
    end

    after(:each) do |example|
      if example.exception
        # TODO improve how we print the output
        puts "$ #{@tsuru_command.last_command}"
        puts @tsuru_command.stdout
        puts @tsuru_command.stderr
      end
    end

    after(:all) do
      @tsuru_command.key_remove('rspec') # Remove previous state if needed
      @tsuru_command.service_unbind('sampleapptestdb', @sampleapp_name)
      @tsuru_command.service_remove('sampleapptestdb') # Remove previous state if needed
      @tsuru_command.app_remove(@sampleapp_name) # Remove previous state if needed
      @tsuru_home.rmrf
    end

    it "should not be able to login via HTTP" do
      @tsuru_command.target_set("ci-insecure")
      @tsuru_command.login(@tsuru_user, @tsuru_pass)
      expect(@tsuru_command.exit_status).not_to eql 0
    end

    it "should be able to login via HTTPS" do
      @tsuru_command.target_set("ci")
      @tsuru_command.login(@tsuru_user, @tsuru_pass)
      expect(@tsuru_command.exit_status).to eql 0
    end


    it "should be able to add the ssh key" do
      @tsuru_command.key_add('rspec', @ssh_id_rsa_pub_path)
      expect(@tsuru_command.exit_status).to eql 0
      expect(@tsuru_command.stdout).to match /Key .* successfully added!/
    end

    it "should be able to create an application" do
      @tsuru_command.app_create(@sampleapp_name, 'python')
      expect(@tsuru_command.exit_status).to eql 0
      expect(@tsuru_command.stdout).to match /App .* has been created/
    end

    it "should be able to create a service" do
      @tsuru_command.service_add('postgresql', 'sampleapptestdb', 'shared')
      expect(@tsuru_command.exit_status).to eql 0
      expect(@tsuru_command.stdout).to match /Service successfully added/
    end

    it "should be able to bind a service to an app" do
      @tsuru_command.service_bind('sampleapptestdb', @sampleapp_name)
      expect(@tsuru_command.exit_status).to eql 0
      expect(@tsuru_command.stdout).to match /Instance .* is now bound to the app .*/
    end

    it "Should be able to push the application" do
      git_url = @tsuru_command.get_app_repository(@sampleapp_name)
      expect(git_url).not_to be_nil
      @git_command.push(git_url)
      expect(@git_command.exit_status).to eql 0
    end

    it "Should be able to connect to the applitation via HTTPS" do
      sampleapp_address = @tsuru_command.get_app_address(@sampleapp_name)
      response = URI.parse("https://#{sampleapp_address}/").open({ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
      expect(response.status).to eq(["200", "OK"])
    end

    it "Should be able to connect to the applitation via HTTPS with a valid cert" do
      pending "We don't have a certificate for this :)"
      sampleapp_address = @tsuru_command.get_app_address(@sampleapp_name)
      response = URI.parse("https://#{sampleapp_address}/").open()
      expect(response.status).to eq(["200", "OK"])
    end

    it "should be able to unbind and bind a service to an app" do
      pending "There is already a bug filed: https://github.com/tsuru/postgres-api/issues/1"
      @tsuru_command.service_unbind('sampleapptestdb', @sampleapp_name)
      expect(@tsuru_command.exit_status).to eql 0
      @tsuru_command.service_bind('sampleapptestdb', @sampleapp_name)
      expect(@tsuru_command.exit_status).to eql 0
      expect(@tsuru_command.stdout).to match /Instance .* is now bound to the app .*/
    end

  end
end



