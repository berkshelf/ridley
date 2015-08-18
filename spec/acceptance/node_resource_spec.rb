require 'spec_helper'

describe "Node API operations", type: "acceptance" do
  let(:server_url)  { Ridley::RSpec::ChefServer.server_url }
  let(:client_name) { "reset" }
  let(:client_key)  { fixtures_path.join('reset.pem').to_s }
  let(:connection)  { Ridley.new(server_url: server_url, client_name: client_name, client_key: client_key) }

  describe "finding a node" do
    let(:node_name) { "ridley.localhost" }
    before { chef_node(node_name) }

    it "returns a Ridley::NodeObject" do
      expect(connection.node.find(node_name)).to be_a(Ridley::NodeObject)
    end
  end

  describe "creating a node" do
    let(:node_name) { "ridley.localhost" }

    it "returns a new Ridley::NodeObject object" do
      expect(connection.node.create(name: node_name)).to be_a(Ridley::NodeObject)
    end

    it "adds a new node to the server" do
      connection.node.create(name: node_name)

      expect(connection.node.all.size).to eq(1)
    end
  end

  describe "deleting a node" do
    let(:node_name) { "ridley.localhost" }
    before { chef_node(node_name) }

    it "returns a Ridley::NodeObject" do
      expect(connection.node.delete(node_name)).to be_a(Ridley::NodeObject)
    end

    it "removes the node from the server" do
      connection.node.delete(node_name)

      expect(connection.node.find(node_name)).to be_nil
    end
  end

  describe "deleting all nodes" do
    before do
      chef_node("ridley.localhost")
      chef_node("motherbrain.localhost")
    end

    it "deletes all nodes from the remote server" do
      connection.node.delete_all

      expect(connection.node.all.size).to eq(0)
    end
  end

  describe "listing all nodes" do
    before do
      chef_node("ridley.localhost")
      chef_node("motherbrain.localhost")
    end

    it "returns an array of Ridley::NodeObject" do
      obj = connection.node.all

      expect(obj).to each be_a(Ridley::NodeObject)
      expect(obj.size).to eq(2)
    end
  end

  describe "updating a node" do
    let(:node_name) { "ridley.localhost" }
    before { chef_node(node_name) }
    let(:target) { connection.node.find(node_name) }

    it "returns the updated node" do
      expect(connection.node.update(target)).to eql(target)
    end

    it "saves a new set of 'normal' attributes" do
      target.normal = normal = {
        "attribute_one" => "value_one",
        "nested" => {
          "other" => "val"
        }
      }

      connection.node.update(target)
      obj = connection.node.find(target)

      expect(obj.normal).to eql(normal)
    end

    it "saves a new set of 'default' attributes" do
      target.default = defaults = {
        "attribute_one" => "val_one",
        "nested" => {
          "other" => "val"
        }
      }

      connection.node.update(target)
      obj = connection.node.find(target)

      expect(obj.default).to eql(defaults)
    end

    it "saves a new set of 'automatic' attributes" do
      target.automatic = automatics = {
        "attribute_one" => "val_one",
        "nested" => {
          "other" => "val"
        }
      }

      connection.node.update(target)
      obj = connection.node.find(target)

      expect(obj.automatic).to eql(automatics)
    end

    it "saves a new set of 'override' attributes" do
      target.override = overrides = {
        "attribute_one" => "val_one",
        "nested" => {
          "other" => "val"
        }
      }

      connection.node.update(target)
      obj = connection.node.find(target)

      expect(obj.override).to eql(overrides)
    end

    it "places a node in a new 'chef_environment'" do
      target.chef_environment = environment = "ridley"

      connection.node.update(target)
      obj = connection.node.find(target)

      expect(obj.chef_environment).to eql(environment)
    end

    it "saves a new 'run_list' for the node" do
      target.run_list = run_list = ["recipe[one]", "recipe[two]"]

      connection.node.update(target)
      obj = connection.node.find(target)

      expect(obj.run_list).to eql(run_list)
    end
  end
end
