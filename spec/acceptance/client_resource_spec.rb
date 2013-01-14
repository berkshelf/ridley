require 'spec_helper'

describe "Client API operations", type: "acceptance" do
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
    connection.client.delete_all
  end

  describe "finding a client" do
    let(:target) do
      Ridley::ClientResource.new(
        connection,
        name: "motherbrain-test",
        admin: false
      )
    end

    before(:each) do
      connection.client.create(target)
    end

    it "returns a valid Ridley::ClientResource" do
      connection.sync do
        obj = client.find(target)

        obj.should be_a(Ridley::ClientResource)
        obj.should be_valid
      end
    end
  end

  describe "creating a client" do
    let(:target) do
      Ridley::ClientResource.new(
        connection,
        name: "motherbrain_test"
      )
    end

    it "returns a Ridley::ClientResource object" do
      connection.sync do
        client.create(target).should be_a(Ridley::ClientResource)
      end
    end

    it "has a value for 'private_key'" do
      connection.sync do
        client.create(target).private_key.should_not be_nil
      end
    end
  end

  describe "deleting a client" do
    let(:target) do
      Ridley::ClientResource.new(
        connection,
        name: "motherbrain-test",
        admin: false
      )
    end

    before(:each) do
      connection.client.create(target)
    end

    it "returns a Ridley::ClientResource object" do
      connection.client.delete(target).should be_a(Ridley::ClientResource)
    end
  end

  describe "deleting all clients" do
    before(:each) do
      connection.sync do
        client.create(name: "ridley-one")
        client.create(name: "ridley-two")
      end
    end

    it "returns an array of Ridley::ClientResource objects" do
      connection.client.delete_all.should each be_a(Ridley::ClientResource)
    end

    it "deletes all clients from the remote" do
      connection.sync do
        client.delete_all

        client.all.should have(0).clients
      end
    end
  end

  describe "listing all clients" do
    it "returns an array of Ridley::ClientResource objects" do
      connection.client.all.should each be_a(Ridley::ClientResource)
    end
  end

  describe "regenerating a client's private key" do
    let(:target) do
      Ridley::ClientResource.new(
        connection,
        name: "motherbrain-test",
        admin: false
      )
    end

    before(:each) do
      connection.client.create(target)
    end

    it "returns a Ridley::ClientResource object with a value for 'private_key'" do
      connection.sync do
        obj = client.regenerate_key(target)

        obj.private_key.should match(/^-----BEGIN RSA PRIVATE KEY-----/)
      end
    end
  end
end
