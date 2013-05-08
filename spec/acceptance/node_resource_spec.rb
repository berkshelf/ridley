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
      connection.node.find(node_name).should be_a(Ridley::NodeObject)
    end
  end

  describe "creating a node" do
    let(:node_name) { "ridley.localhost" }

    it "returns a new Ridley::NodeObject object" do
      connection.node.create(name: node_name).should be_a(Ridley::NodeObject)
    end

    it "adds a new node to the server" do
      connection.node.create(name: node_name)

      connection.node.all.should have(1).node
    end
  end

  describe "deleting a node" do
    let(:node_name) { "ridley.localhost" }
    before { chef_node(node_name) }

    it "returns a Ridley::NodeObject" do
      connection.node.delete(node_name).should be_a(Ridley::NodeObject)
    end

    it "removes the node from the server" do
      connection.node.delete(node_name)

      connection.node.find(node_name).should be_nil
    end
  end

  describe "deleting all nodes" do
    before do
      chef_node("ridley.localhost")
      chef_node("motherbrain.localhost")
    end

    it "deletes all nodes from the remote server" do
      connection.node.delete_all

      connection.node.all.should have(0).nodes
    end
  end

  describe "listing all nodes" do
    before do
      chef_node("ridley.localhost")
      chef_node("motherbrain.localhost")
    end

    it "returns an array of Ridley::NodeObject" do
      obj = connection.node.all

      obj.should each be_a(Ridley::NodeObject)
      obj.should have(2).nodes
    end
  end

  describe "updating a node" do
    let(:node_name) { "ridley.localhost" }
    before { chef_node(node_name) }
    let(:target) { connection.node.find(node_name) }

    it "returns the updated node" do
      connection.node.update(target).should eql(target)
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

      obj.normal.should eql(normal)
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

      obj.default.should eql(defaults)
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

      obj.automatic.should eql(automatics)
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

      obj.override.should eql(overrides)
    end

    it "places a node in a new 'chef_environment'" do
      target.chef_environment = environment = "ridley"

      connection.node.update(target)
      obj = connection.node.find(target)

      obj.chef_environment.should eql(environment)
    end

    it "saves a new 'run_list' for the node" do
      target.run_list = run_list = ["recipe[one]", "recipe[two]"]

      connection.node.update(target)
      obj = connection.node.find(target)

      obj.run_list.should eql(run_list)
    end
  end
end
