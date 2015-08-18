require 'spec_helper'

describe "Environment API operations", type: "acceptance" do
  let(:server_url)  { Ridley::RSpec::ChefServer.server_url }
  let(:client_name) { "reset" }
  let(:client_key)  { fixtures_path.join('reset.pem').to_s }
  let(:connection)  { Ridley.new(server_url: server_url, client_name: client_name, client_key: client_key) }

  describe "finding an environment" do
    before { chef_environment("ridley-test-env") }

    it "returns a valid Ridley::EnvironmentObject object" do
      expect(connection.environment.find("ridley-test-env")).to be_a(Ridley::EnvironmentObject)
    end
  end

  describe "creating an environment" do
    it "returns a valid Ridley::EnvironmentObject object" do
      obj = connection.environment.create(name: "ridley-test-env", description: "a testing env for ridley")

      expect(obj).to be_a(Ridley::EnvironmentObject)
    end

    it "adds an environment to the chef server" do
      old = connection.environment.all.length
      connection.environment.create(name: "ridley")
      expect(connection.environment.all.size).to eq(old + 1)
    end
  end

  describe "deleting an environment" do
    before { chef_environment("ridley-env") }

    it "returns a Ridley::EnvironmentObject object" do
      expect(connection.environment.delete("ridley-env")).to be_a(Ridley::EnvironmentObject)
    end

    it "removes the environment from the server" do
      connection.environment.delete("ridley-env")

      expect(connection.environment.find("ridley-env")).to be_nil
    end

    it "raises Ridley::Errors::HTTPMethodNotAllowed when attempting to delete the '_default' environment" do
      expect {
        connection.environment.delete("_default")
      }.to raise_error(Ridley::Errors::HTTPMethodNotAllowed)
    end
  end

  describe "deleting all environments" do
    before do
      chef_environment("ridley-one")
      chef_environment("ridley-two")
    end

    it "returns an array of Ridley::EnvironmentObject objects" do
      expect(connection.environment.delete_all).to each be_a(Ridley::EnvironmentObject)
    end

    it "deletes all environments but '_default' from the remote" do
      connection.environment.delete_all

      expect(connection.environment.all.size).to eq(1)
    end
  end

  describe "listing all environments" do
    it "should return an array of Ridley::EnvironmentObject objects" do
      expect(connection.environment.all).to each be_a(Ridley::EnvironmentObject)
    end
  end

  describe "updating an environment" do
    before { chef_environment("ridley-env") }
    let(:target ) { connection.environment.find("ridley-env") }

    it "saves a new #description" do
      target.description = description = "ridley testing environment"

      connection.environment.update(target)
      expect(target.reload.description).to eql(description)
    end

    it "saves a new set of 'default_attributes'" do
      target.default_attributes = default_attributes = {
        "attribute_one" => "val_one",
        "nested" => {
          "other" => "val"
        }
      }

      connection.environment.update(target)
      obj = connection.environment.find(target)
      expect(obj.default_attributes).to eql(default_attributes)
    end

    it "saves a new set of 'override_attributes'" do
      target.override_attributes = override_attributes = {
        "attribute_one" => "val_one",
        "nested" => {
          "other" => "val"
        }
      }

      connection.environment.update(target)
      obj = connection.environment.find(target)
      expect(obj.override_attributes).to eql(override_attributes)
    end

    it "saves a new set of 'cookbook_versions'" do
      target.cookbook_versions = cookbook_versions = {
        "nginx" => "1.2.0",
        "tomcat" => "1.3.0"
      }

      connection.environment.update(target)
      obj = connection.environment.find(target)
      expect(obj.cookbook_versions).to eql(cookbook_versions)
    end
  end
end
