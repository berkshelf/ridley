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
    connection.start { client.delete_all }
    WebMock.disable_net_connect!
  end

  before(:each) do
    connection.start { client.delete_all }
  end

  describe "finding a client" do
    let(:target) do
      Ridley::Client.new(
        name: "motherbrain-test",
        admin: false
      )
    end

    before(:each) do
      connection.start { client.create(target) }
    end

    it "returns a Ridley::Environment" do
      connection.start do
        client.find(target).should be_a(Ridley::Client)
      end
    end

    it "returns the target Ridley::Client from the server" do
      connection.start do
        client.find(target).should eql(target)
      end
    end
  end

  describe "creating a client" do
    let(:target) do
      Ridley::Client.new(
        name: "motherbrain-test",
        admin: false
      )
    end

    it "returns a Ridley::Client object" do
      connection.start do
        client.create(target).should be_a(Ridley::Client)
      end
    end

    it "has a value for 'private_key'" do
      connection.start do
        client.create(target).private_key.should_not be_nil
      end
    end
  end

  describe "deleting a client" do
    let(:target) do
      Ridley::Client.new(
        name: "motherbrain-test",
        admin: false
      )
    end

    before(:each) do
      connection.start { client.create(target) }
    end

    it "returns a Ridley::Client object" do
      connection.start do
        client.delete(target).should be_a(Ridley::Client)
      end
    end

    context "when the client does not exist" do
      it "raises a Ridley::Errors::HTTPNotFound error" do
        lambda {
          connection.start do
            client.delete("motherbrain-test")
          end
        }.should raise_error(Ridley::Errors::HTTPNotFound)
      end
    end
  end

  describe "deleting all clients" do
    before(:each) do
      connection.start do
        client.create("ridley-one")
        client.create("ridley-two")
      end
    end

    it "returns an array of Ridley::Client objects" do
      connection.start do
        client.delete_all.should each be_a(Ridley::Client)
      end
    end

    it "deletes all clients from the remote" do
      connection.start do
        client.delete_all

        client.all.should have(0).clients
      end
    end
  end

  describe "listing all clients" do
    it "returns an array of Ridley::Client objects" do
      connection.start do
        client.all.should each be_a(Ridley::Client)
      end
    end
  end

  describe "updating a client" do
    let(:target) do
      Ridley::Client.new(
        name: "motherbrain-test",
        admin: false
      )
    end

    before(:each) do
      connection.start { client.create(target) }
    end

    it "returns a Ridley::Client object" do
      target.admin = true

      connection.start do
        client.update(target).should be_a(Ridley::Client)
      end
    end

    it "updates the resources attributes" do
      target.admin = true

      connection.start do
        client.update(target)

        client.find(target).admin.should be_true
      end
    end
  end
end
