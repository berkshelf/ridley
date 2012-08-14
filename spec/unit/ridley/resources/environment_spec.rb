require 'spec_helper'

describe Ridley::Environment do
  it_behaves_like "a Ridley Resource", Ridley::Environment

  let(:server_url) { "https://api.opscode.com" }
  let(:client_name) { "reset" }
  let(:client_key) { "/Users/reset/.chef/reset.pem" }
  let(:organization) { "vialstudios" }
  let(:config) do
    {
      server_url: server_url,
      client_name: client_name,
      client_key: client_key,
      organization: organization
    }
  end

  let(:connection) { Ridley.connection(config) }

  let(:environment_json) do
    %(
      {
        "name": "crazy-town",
        "default_attributes": {
          "nested_attribute": {
            "status": "running",
            "list": [
              "one-thing"
            ],
            "feelin_good": true
          }
        },
        "description": "Single letter variables. Who the fuck do you think you are?",
        "cookbook_versions": {

        },
        "override_attributes": {
          "mysql": {
            "bind_address": "127.0.0.1",
            "server_root_password": "password_lol"
          }
        },
        "chef_type": "environment"
      }
    )
  end

  before(:each) do
    @original_connection = Ridley::Connection.active
    Ridley::Connection.active = connection
  end

  after(:each) do
    Ridley::Connection.active = @original_connection
  end

  describe "ClassMethods" do
    subject { Ridley::Environment }

    describe "::initialize" do
      before(:each) do
        @env = subject.new(parse_json(environment_json))
      end

      it "has a value for 'name'" do
        @env.name.should eql("crazy-town")
      end

      it "has a value for 'default_attributes'" do
        @env.default_attributes.should be_a(Hash)
        @env.default_attributes.should have_key("nested_attribute")
        @env.default_attributes["nested_attribute"]["status"].should eql("running")
      end

      it "has a value for 'description'" do
        @env.description.should eql("Single letter variables. Who the fuck do you think you are?")
      end

      it "has a value for 'cookbook_version'" do
        @env.cookbook_versions.should be_a(Hash)
      end

      it "has a value for 'override_attributes'" do
        @env.override_attributes.should be_a(Hash)
        @env.override_attributes.should have_key("mysql")
        @env.override_attributes["mysql"].should have_key("bind_address")
      end

      it "has a value for 'chef_type'" do
        @env.chef_type.should eql("environment")
      end
    end

    describe "::create" do
      let(:environment_json) do
        "{\"chef_type\":\"environment\",\"json_class\":\"Chef::Environment\",\"name\":\"ridley-devtest\",\"description\":\"Ridley development test environment\",\"default_attributes\":{},\"override_attributes\":{},\"cookbook_versions\":{}}"
      end

      context "when the environment does not exist" do
        before(:each) do
          stub_request(:post, File.join(server_url, 'environments')).with(body: environment_json).
            to_return(body: %({"uri":"https://api.opscode.com/organizations/vialstudios/environments/ridley-devtest"}))
        end

        it "returns an instance of the created Environment" do
          obj = subject.create(
            name: "ridley-devtest",
            description: "Ridley development test environment"
          )

          obj.should be_a(Ridley::Environment)
          obj.name.should eql("ridley-devtest")
          obj.description.should eql("Ridley development test environment")
        end
      end

      context "when the environment already exists" do
        before(:each) do
          stub_request(:post, File.join(server_url, 'environments')).with(body: environment_json).
            to_return(status: 409, body: %({"error":["Environment already exists"]}))
        end

        it "raises a Ridley::Errors::HTTPConflict error" do
          lambda {
            subject.create(
              name: "ridley-devtest",
              description: "Ridley development test environment"
            )
          }.should raise_error(Ridley::Errors::HTTPConflict, "Environment already exists")
        end
      end
    end

    describe "::find" do
      before(:each) do
        stub_request(:get, File.join(server_url, 'environments/ridley-devtest')).to_return(status: 200, body: environment_json)
        @result = subject.find("ridley-devtest")
      end

      let(:environment_json) do
        "{\"chef_type\":\"environment\",\"json_class\":\"Chef::Environment\",\"name\":\"ridley-devtest\",\"description\":\"Ridley development test environment\",\"default_attributes\":{},\"override_attributes\":{},\"cookbook_versions\":{}}"
      end

      it "returns an instance of Ridley::Environment" do
        @result.should be_a(subject) 
      end

      it "sets the name attribute" do
        @result.name.should eql("ridley-devtest")
      end

      it "sets the description attribute" do
        @result.description.should eql("Ridley development test environment")
      end

      it "sets the default_attributes attribute" do
        @result.default_attributes.should eql(Hash.new)
      end

      it "sets the override_attributes attribute" do
        @result.override_attributes.should eql(Hash.new)
      end

      it "sets the cookbook_versions attribute" do
        @result.cookbook_versions.should eql(Hash.new)
      end
    end

    describe "::update" do
      let(:environment_json) do
        "{\"chef_type\":\"environment\",\"json_class\":\"Chef::Environment\",\"name\":\"ridley-devtest\",\"description\":\"Ridley development test environment\",\"default_attributes\":{},\"override_attributes\":{},\"cookbook_versions\":{}}"
      end

      context "when the environment exists" do
        before(:each) do
          stub_request(:get, File.join(server_url, 'environments/ridley-devtest')).to_return(status: 200, body: environment_json)
          stub_request(:put, File.join(server_url, 'environments/ridley-devtest')).
            with(body: "{\"chef_type\":\"environment\",\"json_class\":\"Chef::Environment\",\"name\":\"ridley-devtest\",\"description\":\"brand new description here!\",\"default_attributes\":{},\"override_attributes\":{},\"cookbook_versions\":{}}").
            to_return(status: 200, body: "{\"chef_type\":\"environment\",\"json_class\":\"Chef::Environment\",\"name\":\"ridley-devtest\",\"description\":\"brand new description here!\",\"default_attributes\":{},\"override_attributes\":{},\"cookbook_versions\":{}}")
        end

        it "returns an updated instance of Ridley::Environment" do
          env = subject.find("ridley-devtest")
          env.description = "brand new description here!"

          updated_env = subject.update(env)
          updated_env.should be_a(Ridley::Environment)
          updated_env.description.should eql("brand new description here!")
        end
      end

      context "when the environment does not exist" do
        before(:each) do
          stub_request(:put, File.join(server_url, 'environments/ridley-devtest')).
            to_return(status: 404, body: "{\"error\":[\"Cannot load environment ridley-devtest\"]}")
        end

        it "raises a Ridley::Errors::HTTPNotFound error" do
          env = subject.new(name: "ridley-devtest")

          lambda {
            subject.update(env)
          }.should raise_error(Ridley::Errors::HTTPNotFound, "Cannot load environment ridley-devtest")
        end
      end
    end

    describe "::delete" do
      let(:environment_json) do
        "{\"chef_type\":\"environment\",\"json_class\":\"Chef::Environment\",\"name\":\"ridley-devtest\",\"description\":\"Ridley development test environment\",\"default_attributes\":{},\"override_attributes\":{},\"cookbook_versions\":{}}"
      end

      before(:each) do
        stub_request(:delete, File.join(server_url, 'environments/ridley-devtest')).to_return(status: 200, body: environment_json)
      end

      it "returns the deleted object" do
        result = subject.delete("ridley-devtest")

        result.should be_a(subject)
        result.name.should eql("ridley-devtest")
      end

      context "when the environment does not exist" do
        before(:each) do
          stub_request(:delete, File.join(server_url, 'environments/ridley-devtest')).
            to_return(status: 404, body: "{\"error\":[\"Cannot load environment ridley-devtest\"]}")
        end

        it "raises a Ridley::Errors::HTTPNotFound error" do
          lambda {
            subject.delete("ridley-devtest")
          }.should raise_error(Ridley::Errors::HTTPNotFound, "Cannot load environment ridley-devtest")
        end
      end
    end

    describe "::all" do
      before(:each) do
        stub_request(:get, File.join(server_url, 'environments')).
          to_return(status: 200, body: %({"test1":"https://api.opscode.com/organizations/vialstudios/environments/test1", "test2":"https://api.opscode.com/organizations/vialstudios/environments/test2"}))
      end

      it "returns an array of Environment objects" do
        result = subject.all
        result.should be_a(Array)
        result.should have(2).items
        result.each { |x| x.should be_a(Ridley::Environment) }
      end

      it "sets a value for the chef_id attribute for each record found" do
        result = subject.all

        result.each { |x| x.name.should_not be_nil }
      end
    end
  end
end
