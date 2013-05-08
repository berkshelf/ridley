require 'spec_helper'

describe "Role API operations", type: "acceptance" do
  let(:server_url)  { Ridley::RSpec::ChefServer.server_url }
  let(:client_name) { "reset" }
  let(:client_key)  { fixtures_path.join('reset.pem').to_s }
  let(:connection)  { Ridley.new(server_url: server_url, client_name: client_name, client_key: client_key) }

  describe "finding a role" do
    let(:role_name) { "ridley-role" }
    before { chef_role(role_name) }

    it "returns a Ridley::RoleObject" do
      connection.role.find(role_name).should be_a(Ridley::RoleObject)
    end
  end

  describe "creating a role" do
    let(:role_name) { "ridley-role" }

    it "returns a new Ridley::RoleObject" do
      connection.role.create(name: role_name).should be_a(Ridley::RoleObject)
    end

    it "adds a new role to the server" do
      connection.role.create(name: role_name)
      connection.role.all.should have(1).role
    end
  end

  describe "deleting a role" do
    let(:role_name) { "ridley-role" }
    before { chef_role(role_name) }

    it "returns the deleted Ridley::RoleObject resource" do
      connection.role.delete(role_name).should be_a(Ridley::RoleObject)
    end

    it "removes the role from the server" do
      connection.role.delete(role_name)

      connection.role.find(role_name).should be_nil
    end
  end

  describe "deleting all roles" do
    before do
      chef_role("role_one")
      chef_role("role_two")
    end

    it "deletes all nodes from the remote server" do
      connection.role.delete_all

      connection.role.all.should have(0).roles
    end
  end

  describe "listing all roles" do
    before do
      chef_role("role_one")
      chef_role("role_two")
    end

    it "should return an array of Ridley::RoleObject" do
      obj = connection.role.all

      obj.should have(2).roles
      obj.should each be_a(Ridley::RoleObject)
    end
  end

  describe "updating a role" do
    let(:role_name) { "ridley-role" }
    before { chef_role(role_name) }
    let(:target) { connection.role.find(role_name) }

    it "returns an updated Ridley::RoleObject object" do
      connection.role.update(target).should eql(target)
    end

    it "saves a new run_list" do
      target.run_list = run_list = ["recipe[one]", "recipe[two]"]

      connection.role.update(target)
      obj = connection.role.find(target)

      obj.run_list.should eql(run_list)
    end

    it "saves a new env_run_lists" do
      target.env_run_lists = env_run_lists = {
        "production" => ["recipe[one]"],
        "development" => ["recipe[two]"]
      }

      connection.role.update(target)
      obj = connection.role.find(target)

      obj.env_run_lists.should eql(env_run_lists)
    end

    it "saves a new description" do
      target.description = description = "a new description!"

      connection.role.update(target)
      obj = connection.role.find(target)

      obj.description.should eql(description)
    end

    it "saves a new default_attributes" do
      target.default_attributes = defaults = {
        "attribute_one" => "value_one",
        "nested" => {
          "other" => false
        }
      }

      connection.role.update(target)
      obj = connection.role.find(target)

      obj.default_attributes.should eql(defaults)
    end

    it "saves a new override_attributes" do
      target.override_attributes = overrides = {
        "attribute_two" => "value_two",
        "nested" => {
          "other" => false
        }
      }

      connection.role.update(target)
      obj = connection.role.find(target)

      obj.override_attributes.should eql(overrides)
    end
  end
end
