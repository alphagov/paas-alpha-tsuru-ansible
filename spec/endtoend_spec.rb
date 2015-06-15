require 'minigit'

describe "TsuruEndToEnd" do
  context "deploying an application" do
      before(:all) do
        @tsuru_home = Tempdir.new('tsuru-command')
        @tsuru_api_url = "https://ci-api.tsuru.paas.alphagov.co.uk" 
        @tsuru_api_url_insecure = "http://ci-api.tsuru.paas.alphagov.co.uk:8080" 
        @tsuru_command = TsuruCommandLine.new(@tsuru_home)  
        @tsuru_command.target_add("ci", @tsuru_api_url)
        @tsuru_command.target_add("ci-insecure", @tsuru_api_url_insecure)
        @tsuru_user = ENV['TSURU_USER']
        @tsuru_pass = ENV['TSURU_PASS']
        
        #@tsuru_example_app_minigit = MiniGit.new(File.join(@tsuru_home, 'tsuru_example_app'))
        MiniGit.git :clone, "https://github.com/alphagov/flask-sqlalchemy-postgres-heroku-example.git", @tsuru_home.path+"/sampleapp"
        @tsuru_example_app_minigit = MiniGit.new(File.join(@tsuru_home, 'sampleapp'))
      end

      
      it "should not be able to login via HTTP" do
        @tsuru_command.target_set("ci")
        @tsuru_command.login(@tsuru_user, @tsuru_pass)
        expect(@tsuru_command.exit_status).to eql 0
      end
      it "should be able to login via HTTP" do
        @tsuru_command.target_set("ci-insecure")
        @tsuru_command.login(@tsuru_user, @tsuru_pass)
        expect(@tsuru_command.exit_status).not_to eql 0
      end
    end
 
end



