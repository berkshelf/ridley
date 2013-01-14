require 'spec_helper'

describe "Role API operations", type: "acceptance" do
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

  before(:each) { connection.role.delete_all }

  describe "finding a role" do
    let(:target) do
      Ridley::RoleResource.new(
        connection,
        name: "ridley-test",
        description: "a testing role for ridley" 
      )
    end

    before(:each) do
      connection.role.create(target)
    end

    it "returns the target Ridley::RoleResource from the server" do
      connection.role.find(target.name).should eql(target)
    end
  end

  describe "creating a role" do
    let(:target) do
      Ridley::RoleResource.new(
        connection,
        name: "ridley-test",
        description: "a testing role for ridley" 
      )
    end

    it "returns a new Ridley::RoleResource" do
      connection.role.create(target).should eql(target)
    end

    it "adds a new role to the server" do
      connection.sync do
        role.create(target)

        role.all.should have(1).role
      end
    end
  end

  describe "deleting a role" do
    let(:target) do
      Ridley::RoleResource.new(
        connection,
        name: "ridley-role-one"
      )
    end

    before(:each) do
      connection.role.create(target)
    end

    it "returns the deleted Ridley::RoleResource resource" do
      connection.role.delete(target).should eql(target)
    end

    it "removes the role from the server" do
      connection.sync do
        role.delete(target)

        role.find(target).should be_nil
      end
    end
  end

  describe "deleting all roles" do
    it "deletes all nodes from the remote server" do
      connection.sync do
        role.delete_all

        role.all.should have(0).roles
      end
    end
  end

  describe "listing all roles" do
    before(:each) do
      connection.sync do
        role.create(name: "jamie")
        role.create(name: "winsor")
      end
    end

    it "should return an array of Ridley::RoleResource objects" do
      connection.sync do
        obj = role.all

        obj.should have(2).roles
        obj.should each be_a(Ridley::RoleResource)
      end
    end
  end

  describe "updating a role" do
    let(:target) do
      Ridley::RoleResource.new(
        connection,
        name: "ridley-role-one"
      )
    end

    before(:each) do
      connection.role.create(target)
    end

    it "returns an updated Ridley::RoleResource object" do
      connection.role.update(target).should eql(target)
    end

    it "saves a new run_list" do
      target.run_list = run_list = ["recipe[one]", "recipe[two]"]

      connection.sync do
        role.update(target)
        obj = role.find(target)

        obj.run_list.should eql(run_list)
      end
    end

    it "saves a new env_run_lists" do
      target.env_run_lists = env_run_lists = {
        "production" => ["recipe[one]"],
        "development" => ["recipe[two]"]
      }

      connection.sync do
        role.update(target)
        obj = role.find(target)

        obj.env_run_lists.should eql(env_run_lists)
      end
    end

    it "saves a new description" do
      target.description = description = "a new description!"

      connection.sync do
        role.update(target)
        obj = role.find(target)

        obj.description.should eql(description)
      end
    end

    it "saves a new default_attributes" do
      target.default_attributes = defaults = {
        "attribute_one" => "value_one",
        "nested" => {
          "other" => false
        }
      }

      connection.sync do
        role.update(target)
        obj = role.find(target)

        obj.default_attributes.should eql(defaults)
      end
    end

    it "saves a new override_attributes" do
      target.override_attributes = overrides = {
        "attribute_two" => "value_two",
        "nested" => {
          "other" => false
        }
      }

      connection.sync do
        role.update(target)
        obj = role.find(target)

        obj.override_attributes.should eql(overrides)
      end
    end
  end
end
