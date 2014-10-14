require 'spec_helper'

describe "User API operations", type: "wip" do
  let(:server_url)  { Ridley::RSpec::ChefServer.server_url }
  let(:user_name) { "reset" }
  let(:user_key)  { fixtures_path.join('reset.pem').to_s }
  let(:connection)  { Ridley.new(server_url: server_url, client_name: user_name, client_key: user_key) }

  describe "finding a user" do
    context "when the server has a user of the given name" do
      before { chef_user("reset", admin: false) }

      it "returns a UserObject" do
        connection.user.find("reset").should be_a(Ridley::UserObject)
      end
    end

    context "when the server does not have the user" do
      it "returns a nil value" do
        connection.user.find("not_there").should be_nil
      end
    end
  end

  describe "creating a user" do
    it "returns a Ridley::UserObject" do
      connection.user.create(name: "reset").should be_a(Ridley::UserObject)
    end

    it "adds a user to the chef server" do
      old = connection.user.all.length
      connection.user.create(name: "reset")
      connection.user.all.should have(old + 1).items
    end

    it "has a value for #private_key" do
      connection.user.create(name: "reset").private_key.should_not be_nil
    end
  end

  describe "deleting a user" do
    before { chef_user("reset", admin: false) }

    it "returns a Ridley::UserObject object" do
      connection.user.delete("reset").should be_a(Ridley::UserObject)
    end

    it "removes the user from the server" do
      connection.user.delete("reset")

      connection.user.find("reset").should be_nil
    end
  end

  describe "deleting all users" do
    before(:each) do
      chef_user("reset", admin: false)
      chef_user("jwinsor", admin: false)
    end

    it "returns an array of Ridley::UserObject objects" do
      connection.user.delete_all.should each be_a(Ridley::UserObject)
    end

    it "deletes all users from the remote" do
      connection.user.delete_all
      connection.user.all.should have(0).users
    end
  end

  describe "listing all users" do
    before(:each) do
      chef_user("reset", admin: false)
      chef_user("jwinsor", admin: false)
    end

    it "returns an array of Ridley::UserObject objects" do
      connection.user.all.should each be_a(Ridley::UserObject)
    end

    it "returns all of the users on the server" do
      connection.user.all.should have(3).items
    end
  end

  describe "regenerating a user's private key" do
    before { chef_user("reset", admin: false) }

    it "returns a Ridley::UserObject object with a value for #private_key" do
      connection.user.regenerate_key("reset").private_key.should match(/^-----BEGIN RSA PRIVATE KEY-----/)
    end
  end

  describe "authenticating a user" do
    before { chef_user('reset', password: 'swordfish') }

    it "returns true when given valid username & password" do
      expect(connection.user.authenticate('reset', 'swordfish')).to be_true
    end

    it "returns false when given valid username & invalid password" do
      expect(connection.user.authenticate('reset', "not a swordfish")).to be_false
    end

    it "returns false when given invalid username & valid password" do
      expect(connection.user.authenticate("someone-else", 'swordfish')).to be_false
    end

    it "works also on a User object level" do
      expect(connection.user.find('reset').authenticate('swordfish')).to be_true
      expect(connection.user.find('reset').authenticate('not a swordfish')).to be_false
    end
  end

  describe "changing user's password" do
    before { chef_user('reset', password: 'swordfish') }
    subject { connection.user.find('reset') }

    it "changes the password with which user can authenticate" do
      expect(subject.authenticate('swordfish')).to be_true
      expect(subject.authenticate('salmon')).to be_false

      subject.password = 'salmon'
      subject.save

      expect(subject.authenticate('swordfish')).to be_false
      expect(subject.authenticate('salmon')).to be_true
    end
  end
end
