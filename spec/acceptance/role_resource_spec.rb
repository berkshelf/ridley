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
  after(:all) { WebMock.disable_net_connect! }

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
    let(:target) do
      Ridley::Role.new(
        name: "ridley-role-one"
      )
    end

    before(:each) do
      connection.start { role.create(target) }
    end

    it "returns the deleted Ridley::Role resource" do
      connection.start do
        role.delete(target).should eql(target)
      end
    end

    it "removes the role from the server" do
      connection.start do
        role.delete(target)

        role.find(target).should be_nil
      end
    end
  end

  describe "deleting all roles" do
    it "deletes all nodes from the remote server" do
      connection.start { role.delete_all }

      connection.start { role.all.should have(0).roles }
    end
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
    let(:target) do
      Ridley::Role.new(
        name: "ridley-role-one"
      )
    end

    before(:each) do
      connection.start { role.create(target) }
    end

    it "returns an updated Ridley::Role object" do
      connection.start do
        role.update(target).should eql(target)
      end
    end

    it "saves a new run_list" do
      target.run_list = run_list = ["recipe[one]", "recipe[two]"]

      connection.start do
        role.update(target)
        obj = role.find(target)

        obj.run_list.should eql(run_list)
      end
    end

    it "saves a new env_run_lists" do
      target.env_run_lists = env_run_lists = {
        production: ["recipe[one]"],
        development: ["recipe[two]"]
      }

      connection.start do
        role.update(target)
        obj = role.find(target)

        obj.env_run_lists.should eql(env_run_lists)
      end
    end

    it "saves a new description" do
      target.description = description = "a new description!"

      connection.start do
        role.update(target)
        obj = role.find(target)

        obj.description.should eql(description)
      end
    end

    it "saves a new default_attributes" do
      target.default_attributes = defaults = {
        attribute_one: "value_one",
        nested: {
          other: false
        }
      }

      connection.start do
        role.update(target)
        obj = role.find(target)

        obj.default_attributes.should eql(defaults)
      end
    end

    it "saves a new override_attributes" do
      target.override_attributes = overrides = {
        attribute_two: "value_two",
        nested: {
          other: false
        }
      }

      connection.start do
        role.update(target)
        obj = role.find(target)

        obj.override_attributes.should eql(overrides)
      end
    end
  end
end
