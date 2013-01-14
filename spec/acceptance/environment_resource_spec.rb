require 'spec_helper'

describe "Environment API operations", type: "acceptance" do
  let(:server_url) { "https://api.opscode.com/organizations/ridley" }
  let(:client_name) { "reset" }
  let(:client_key) { "/Users/reset/.chef/reset.pem" }

  let(:connection) do
    Ridley.new(
      server_url: server_url,
      client_name: client_name,
      client_key: client_key
    )
  end

  before(:all) { WebMock.allow_net_connect! }
  after(:all) { WebMock.disable_net_connect! }

  before(:each) do
    connection.environment.delete_all
  end

  describe "finding an environment" do
    let(:target) do
      Ridley::EnvironmentResource.new(
        connection,
        name: "ridley-test-env"
      )
    end

    before(:each) do
      connection.environment.create(target)
    end

    it "returns a valid Ridley::EnvironmentResource object" do
      connection.sync do
        obj = environment.find(target)

        obj.should be_a(Ridley::EnvironmentResource)
        obj.should be_valid
      end
    end
  end

  describe "creating an environment" do
    let(:target) do
      Ridley::EnvironmentResource.new(
        connection,
        name: "ridley-test-env",
        description: "a testing environment for ridley"
      )
    end

    it "returns a valid Ridley::EnvironmentResource object" do
      connection.sync do
        obj = environment.create(target)

        obj.should be_a(Ridley::EnvironmentResource)
        obj.should be_valid
      end
    end
  end

  describe "deleting an environment" do
    it "raises Ridley::Errors::HTTPMethodNotAllowed when attempting to delete the '_default' environment" do
      lambda {
        connection.environment.delete("_default")
      }.should raise_error(Ridley::Errors::HTTPMethodNotAllowed)
    end
  end

  describe "deleting all environments" do
    before(:each) do
      connection.sync do
        environment.create(name: "ridley-one")
        environment.create(name: "ridley-two")
      end
    end

    it "returns an array of Ridley::EnvironmentResource objects" do
      connection.environment.delete_all.should each be_a(Ridley::EnvironmentResource)
    end

    it "deletes all environments but '_default' from the remote" do
      connection.sync do
        environment.delete_all

        environment.all.should have(1).clients
        environment.find("_default").should_not be_nil
      end
    end
  end

  describe "listing all environments" do
    it "should return an array of Ridley::EnvironmentResource objects" do
      connection.environment.all.should each be_a(Ridley::EnvironmentResource)
    end
  end

  describe "updating an environment" do
    let(:target) do
      Ridley::EnvironmentResource.new(
        connection,
        name: "ridley-env-test"
      )
    end

    before(:each) do
      connection.environment.create(target)
    end

    it "saves a new 'description'" do
      target.description = description = "ridley testing environment"

      connection.sync do
        environment.update(target)
        obj = environment.find(target)

        obj.description.should eql(description)
      end
    end

    it "saves a new set of 'default_attributes'" do
      target.default_attributes = default_attributes = {
        "attribute_one" => "val_one",
        "nested" => {
          "other" => "val"
        }
      }

      connection.sync do
        environment.update(target)
        obj = environment.find(target)

        obj.default_attributes.should eql(default_attributes)
      end
    end

    it "saves a new set of 'override_attributes'" do
      target.override_attributes = override_attributes = {
        "attribute_one" => "val_one",
        "nested" => {
          "other" => "val"
        }
      }

      connection.sync do
        environment.update(target)
        obj = environment.find(target)

        obj.override_attributes.should eql(override_attributes)
      end
    end

    it "saves a new set of 'cookbook_versions'" do
      target.cookbook_versions = cookbook_versions = {
        "nginx" => "1.2.0",
        "tomcat" => "1.3.0"
      }

      connection.sync do
        environment.update(target)
        obj = environment.find(target)

        obj.cookbook_versions.should eql(cookbook_versions)
      end
    end
  end
end
