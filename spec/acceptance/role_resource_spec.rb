require 'spec_helper'

describe "Role API operations", type: "acceptance" do
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

  before(:all) { WebMock.allow_net_connect! }

  after(:all) do
    connection.start { role.delete_all }
    WebMock.disable_net_connect!
  end

  before(:each) do
    connection.start { role.delete_all }
  end

  describe "finding a role" do
    let(:target) do
      Ridley::Role.new(
        name: "ridley-test",
        description: "a testing role for ridley" 
      )
    end

    before(:each) do
      connection.start { role.create(target) }
    end

    it "returns the target Ridley::Role from the server" do
      connection.start do
        role.find(target.name).should eql(target)
      end
    end
  end

  describe "creating a role" do
    let(:target) do
      Ridley::Role.new(
        name: "ridley-test",
        description: "a testing role for ridley" 
      )
    end

    it "returns a new Ridley::Role" do
      connection.start do
        role.create(target).should eql(target)
      end
    end

    it "adds a new role to the server" do
      connection.start do
        role.create(target)
      end

      connection.start do
        role.all.should have(1).role
      end
    end
  end

  describe "deleting a role" do
    pending
  end

  describe "deleting all roles" do
    pending
  end

  describe "listing all roles" do
    before(:each) do
      connection.start do
        role.create(name: "jamie")
        role.create(name: "winsor")
      end
    end

    it "should return an array of Ridley::Role objects" do
      connection.start do
        obj = role.all

        obj.should have(2).roles
        obj.should each be_a(Ridley::Role)
      end
    end
  end

  describe "updating a role" do
    pending
  end
end
