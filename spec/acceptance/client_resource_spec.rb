require 'spec_helper'

describe "Client API operations", type: "acceptance" do
  let(:server_url)  { Ridley::RSpec::ChefServer.server_url }
  let(:client_name) { "reset" }
  let(:client_key)  { fixtures_path.join('reset.pem').to_s }
  let(:connection)  { Ridley.new(server_url: server_url, client_name: client_name, client_key: client_key) }

  describe "finding a client" do
    context "when the server has a client of the given name" do
      before { chef_client("reset", admin: false) }

      it "returns a ClientObject" do
        connection.client.find("reset").should be_a(Ridley::ClientObject)
      end
    end

    context "when the server does not have the client" do
      it "returns a nil value" do
        connection.client.find("not_there").should be_nil
      end
    end
  end

  describe "creating a client" do
    it "returns a Ridley::ClientObject" do
      connection.client.create(name: "reset").should be_a(Ridley::ClientObject)
    end

    it "adds a client to the chef server" do
      old = connection.client.all.length
      connection.client.create(name: "reset")
      connection.client.all.should have(old + 1).items
    end

    it "has a value for #private_key" do
      connection.client.create(name: "reset").private_key.should_not be_nil
    end
  end

  describe "deleting a client" do
    before { chef_client("reset", admin: false) }

    it "returns a Ridley::ClientObject object" do
      connection.client.delete("reset").should be_a(Ridley::ClientObject)
    end

    it "removes the client from the server" do
      connection.client.delete("reset")

      connection.client.find("reset").should be_nil
    end
  end

  describe "deleting all clients" do
    before(:each) do
      chef_client("reset", admin: false)
      chef_client("jwinsor", admin: false)
    end

    it "returns an array of Ridley::ClientObject objects" do
      connection.client.delete_all.should each be_a(Ridley::ClientObject)
    end

    it "deletes all clients from the remote" do
      connection.client.delete_all
      connection.client.all.should have(0).clients
    end
  end

  describe "listing all clients" do
    before(:each) do
      chef_client("reset", admin: false)
      chef_client("jwinsor", admin: false)
    end

    it "returns an array of Ridley::ClientObject objects" do
      connection.client.all.should each be_a(Ridley::ClientObject)
    end

    it "returns all of the clients on the server" do
      connection.client.all.should have(4).items
    end
  end

  describe "regenerating a client's private key" do
    before { chef_client("reset", admin: false) }

    it "returns a Ridley::ClientObject object with a value for #private_key" do
      connection.client.regenerate_key("reset").private_key.should match(/^-----BEGIN RSA PRIVATE KEY-----/)
    end
  end
end
