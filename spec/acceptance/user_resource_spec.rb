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
        expect(connection.user.find("reset")).to be_a(Ridley::UserObject)
      end
    end

    context "when the server does not have the user" do
      it "returns a nil value" do
        expect(connection.user.find("not_there")).to be_nil
      end
    end
  end

  describe "creating a user" do
    it "returns a Ridley::UserObject" do
      expect(connection.user.create(name: "reset")).to be_a(Ridley::UserObject)
    end

    it "adds a user to the chef server" do
      old = connection.user.all.length
      connection.user.create(name: "reset")
      expect(connection.user.all.size).to eq(old + 1)
    end

    it "has a value for #private_key" do
      expect(connection.user.create(name: "reset").private_key).not_to be_nil
    end
  end

  describe "deleting a user" do
    before { chef_user("reset", admin: false) }

    it "returns a Ridley::UserObject object" do
      expect(connection.user.delete("reset")).to be_a(Ridley::UserObject)
    end

    it "removes the user from the server" do
      connection.user.delete("reset")

      expect(connection.user.find("reset")).to be_nil
    end
  end

  describe "deleting all users" do
    before(:each) do
      chef_user("reset", admin: false)
      chef_user("jwinsor", admin: false)
    end

    it "returns an array of Ridley::UserObject objects" do
      expect(connection.user.delete_all).to each be_a(Ridley::UserObject)
    end

    it "deletes all users from the remote" do
      connection.user.delete_all
      expect(connection.user.all.size).to eq(0)
    end
  end

  describe "listing all users" do
    before(:each) do
      chef_user("reset", admin: false)
      chef_user("jwinsor", admin: false)
    end

    it "returns an array of Ridley::UserObject objects" do
      expect(connection.user.all).to each be_a(Ridley::UserObject)
    end

    it "returns all of the users on the server" do
      expect(connection.user.all.size).to eq(3)
    end
  end

  describe "regenerating a user's private key" do
    before { chef_user("reset", admin: false) }

    it "returns a Ridley::UserObject object with a value for #private_key" do
      expect(connection.user.regenerate_key("reset").private_key).to match(/^-----BEGIN RSA PRIVATE KEY-----/)
    end
  end

  describe "authenticating a user" do
    before { chef_user('reset', password: 'swordfish') }

    it "returns true when given valid username & password" do
      expect(connection.user.authenticate('reset', 'swordfish')).to be_truthy
    end

    it "returns false when given valid username & invalid password" do
      expect(connection.user.authenticate('reset', "not a swordfish")).to be_falsey
    end

    it "returns false when given invalid username & valid password" do
      expect(connection.user.authenticate("someone-else", 'swordfish')).to be_falsey
    end

    it "works also on a User object level" do
      expect(connection.user.find('reset').authenticate('swordfish')).to be_truthy
      expect(connection.user.find('reset').authenticate('not a swordfish')).to be_falsey
    end
  end

  describe "changing user's password" do
    before { chef_user('reset', password: 'swordfish') }
    subject { connection.user.find('reset') }

    it "changes the password with which user can authenticate" do
      expect(subject.authenticate('swordfish')).to be_truthy
      expect(subject.authenticate('salmon')).to be_falsey

      subject.password = 'salmon'
      subject.save

      expect(subject.authenticate('swordfish')).to be_falsey
      expect(subject.authenticate('salmon')).to be_truthy
    end
  end
end
