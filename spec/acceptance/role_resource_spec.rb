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
      expect(connection.role.find(role_name)).to be_a(Ridley::RoleObject)
    end
  end

  describe "creating a role" do
    let(:role_name) { "ridley-role" }

    it "returns a new Ridley::RoleObject" do
      expect(connection.role.create(name: role_name)).to be_a(Ridley::RoleObject)
    end

    it "adds a new role to the server" do
      connection.role.create(name: role_name)
      expect(connection.role.all.size).to eq(1)
    end
  end

  describe "deleting a role" do
    let(:role_name) { "ridley-role" }
    before { chef_role(role_name) }

    it "returns the deleted Ridley::RoleObject resource" do
      expect(connection.role.delete(role_name)).to be_a(Ridley::RoleObject)
    end

    it "removes the role from the server" do
      connection.role.delete(role_name)

      expect(connection.role.find(role_name)).to be_nil
    end
  end

  describe "deleting all roles" do
    before do
      chef_role("role_one")
      chef_role("role_two")
    end

    it "deletes all nodes from the remote server" do
      connection.role.delete_all

      expect(connection.role.all.size).to eq(0)
    end
  end

  describe "listing all roles" do
    before do
      chef_role("role_one")
      chef_role("role_two")
    end

    it "should return an array of Ridley::RoleObject" do
      obj = connection.role.all

      expect(obj.size).to eq(2)
      expect(obj).to each be_a(Ridley::RoleObject)
    end
  end

  describe "updating a role" do
    let(:role_name) { "ridley-role" }
    before { chef_role(role_name) }
    let(:target) { connection.role.find(role_name) }

    it "returns an updated Ridley::RoleObject object" do
      expect(connection.role.update(target)).to eql(target)
    end

    it "saves a new run_list" do
      target.run_list = run_list = ["recipe[one]", "recipe[two]"]

      connection.role.update(target)
      obj = connection.role.find(target)

      expect(obj.run_list).to eql(run_list)
    end

    it "saves a new env_run_lists" do
      target.env_run_lists = env_run_lists = {
        "production" => ["recipe[one]"],
        "development" => ["recipe[two]"]
      }

      connection.role.update(target)
      obj = connection.role.find(target)

      expect(obj.env_run_lists).to eql(env_run_lists)
    end

    it "saves a new description" do
      target.description = description = "a new description!"

      connection.role.update(target)
      obj = connection.role.find(target)

      expect(obj.description).to eql(description)
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

      expect(obj.default_attributes).to eql(defaults)
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

      expect(obj.override_attributes).to eql(overrides)
    end
  end
end
