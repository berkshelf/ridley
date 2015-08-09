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
        expect(connection.client.find("reset")).to be_a(Ridley::ClientObject)
      end
    end

    context "when the server does not have the client" do
      it "returns a nil value" do
        expect(connection.client.find("not_there")).to be_nil
      end
    end
  end

  describe "creating a client" do
    it "returns a Ridley::ClientObject" do
      expect(connection.client.create(name: "reset")).to be_a(Ridley::ClientObject)
    end

    it "adds a client to the chef server" do
      old = connection.client.all.length
      connection.client.create(name: "reset")
      expect(connection.client.all.size).to eq(old + 1)
    end

    it "has a value for #private_key" do
      expect(connection.client.create(name: "reset").private_key).not_to be_nil
    end
  end

  describe "deleting a client" do
    before { chef_client("reset", admin: false) }

    it "returns a Ridley::ClientObject object" do
      expect(connection.client.delete("reset")).to be_a(Ridley::ClientObject)
    end

    it "removes the client from the server" do
      connection.client.delete("reset")

      expect(connection.client.find("reset")).to be_nil
    end
  end

  describe "deleting all clients" do
    before(:each) do
      chef_client("reset", admin: false)
      chef_client("jwinsor", admin: false)
    end

    it "returns an array of Ridley::ClientObject objects" do
      expect(connection.client.delete_all).to each be_a(Ridley::ClientObject)
    end

    it "deletes all clients from the remote" do
      connection.client.delete_all
      expect(connection.client.all.size).to eq(0)
    end
  end

  describe "listing all clients" do
    before(:each) do
      chef_client("reset", admin: false)
      chef_client("jwinsor", admin: false)
    end

    it "returns an array of Ridley::ClientObject objects" do
      expect(connection.client.all).to each be_a(Ridley::ClientObject)
    end

    it "returns all of the clients on the server" do
      expect(connection.client.all.size).to eq(4)
    end
  end

  describe "regenerating a client's private key" do
    before { chef_client("reset", admin: false) }

    it "returns a Ridley::ClientObject object with a value for #private_key" do
      expect(connection.client.regenerate_key("reset").private_key).to match(/^-----BEGIN RSA PRIVATE KEY-----/)
    end
  end
end
