require 'spec_helper'

describe "Node API operations" do
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
    connection.start { node.delete_all }
    WebMock.disable_net_connect!
  end

  before(:each) do
    connection.start { node.delete_all }
  end

  describe "finding a node" do
    let(:target) do
      Ridley::Node.new(
        name: "ridley-one"
      )
    end

    before(:each) do
      connection.start { node.create(target) }
    end

    it "returns a Ridley::Node object" do
      connection.start do
        node.find(target.name).should eql(target)
      end
    end
  end

  describe "creating a node" do
    let(:target) do
      Ridley::Node.new(
        name: "ridley-one"
      )
    end
    
    it "returns a new Ridley::Node object" do
      connection.start do
        node.create(target).should eql(target)
      end
    end

    it "adds a new node to the server" do
      connection.start do
        node.create(target)

        node.all.should have(1).node
      end
    end
  end

  describe "deleting a node" do
    let(:target) do
      Ridley::Node.new(
        name: "ridley-one"
      )
    end

    before(:each) do
      connection.start { node.create(target) }
    end

    it "returns the deleted object" do
      connection.start do
        node.delete(target).should eql(target)
      end
    end

    it "removes the node from the server" do
      connection.start do
        node.delete(target)

        node.find(target).should be_nil
      end
    end
  end

  describe "deleting all nodes" do
    it "deletes all nodes from the remote server" do
      connection.start { node.delete_all }

      connection.start { node.all.should have(0).nodes }
    end
  end

  describe "listing all nodes" do
    before(:each) do
      connection.start do
        node.create(name: "ridley-one")
        node.create(name: "ridley-two")
      end
    end

    it "returns an array of Ridley::Node objects" do
      connection.start do
        obj = node.all
        
        obj.should each be_a(Ridley::Node)
        obj.should have(2).nodes
      end
    end
  end

  describe "updating a node" do
    let(:target) do
      Ridley::Node.new(
        name: "ridley-one"
      )
    end

    before(:each) do
      connection.start { node.create(target) }
    end

    it "returns the updated node" do
      target.description = "a description!"

      connection.start do
        obj = node.update(target)

        obj.should eql(target)
      end
    end

    it "updates the node on the remote server" do
      target.description = "wow, another description"

      connection.start do
        node.update(target)
        obj = node.find(target)

        obj.description.should eql("wow, another description")
      end
    end
  end
end
