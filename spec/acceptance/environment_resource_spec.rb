require 'spec_helper'

describe "Environment API operations" do
  let(:server_url) { "https://api.opscode.com" }
  let(:client_name) { "reset" }
  let(:client_key) { "/Users/reset/.chef/reset.pem" }
  let(:organization) { "vialstudios" }

  let(:connection) do
    Ridley.connection(
      server_url: server_url,
      client_name: client_name,
      client_key: client_key,
      organization: organization
    )
  end

  before(:all) do
    WebMock.allow_net_connect!
  end

  after(:all) do
    WebMock.disable_net_connect!
  end

  describe "finding an environment" do
    pending
  end

  describe "creating an environment" do
    pending
  end

  describe "deleting an environment" do
    it "raises Ridley::Errors::HTTPMethodNotAllowed when attempting to delete the '_default' environment" do
      lambda {
        connection.start { environment.delete("_default") }
      }.should raise_error(Ridley::Errors::HTTPMethodNotAllowed)
    end
  end

  describe "deleting all environments" do
    before(:each) do
      connection.start do
        environment.create(name: "ridley-one")
        environment.create(name: "ridley-two")
      end
    end

    it "returns an array of Ridley::Environment objects" do
      connection.start do
        environment.delete_all.should each be_a(Ridley::Environment)
      end
    end

    it "deletes all environments but '_default' from the remote" do
      connection.start do
        environment.delete_all

        environment.all.should have(1).clients
        environment.find("_default").should_not be_nil
      end
    end
  end

  describe "listing all environments" do
    it "should return an array of Ridley::Environment objects" do
      connection.start do
        environment.all.should each be_a(Ridley::Environment)
      end
    end
  end

  describe "updating an environment" do
    pending
  end
end
