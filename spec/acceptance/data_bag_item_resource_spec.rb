require 'spec_helper'

describe "DataBag API operations", type: "acceptance" do
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

  before(:all) do
    connection.data_bag.delete_all
    @databag = connection.data_bag.create(name: "ridley-test")
  end

  before(:each) do
    @databag.item.delete_all
  end

  describe "listing data bag items" do
    context "when the data bag has no items" do
      before(:each) do
        @databag.item.delete_all
      end

      it "returns an empty array" do
        @databag.item.all.should have(0).items
      end
    end

    context "when the data bag has items" do
      before(:each) do
        @databag.item.create(id: "one")
        @databag.item.create(id: "two")
      end

      it "returns an array with each item" do
        @databag.item.all.should have(2).items
      end
    end
  end

  describe "creating a data bag item" do
    it "adds a data bag item to the collection of data bag items" do
      @databag.item.create(id: "appconfig", host: "host.local", port: 80, admin: false, servers: ["one"])

      @databag.item.all.should have(1).item
    end

    context "when an 'id' field is missing" do
      it "raises an Ridley::Errors::InvalidResource error" do
        lambda {
          @databag.item.create(name: "jamie")
        }.should raise_error(Ridley::Errors::InvalidResource)
      end
    end
  end

  describe "retrieving a data bag item" do
    it "returns the desired item in the data bag" do
      attributes = {
        "id" => "appconfig",
        "host" => "host.local",
        "port" => 80,
        "admin" => false,
        "servers" => [
          "one"
        ]
      }
      @databag.item.create(attributes)

      @databag.item.find("appconfig").to_hash.should eql(attributes)
    end
  end

  describe "deleting a data bag item" do
    let(:attributes) do
      {
        "id" => "appconfig",
        "host" => "host.local"
      }
    end

    before(:each) do
      @databag.item.create(attributes)
    end

    it "returns the deleted data bag item" do
      dbi = @databag.item.delete(attributes["id"])

      dbi.should be_a(Ridley::DataBagItemResource)
      dbi.attributes.should eql(attributes)
    end

    it "deletes the data bag item from the server" do
      @databag.item.delete(attributes["id"])

      @databag.item.find(attributes["id"]).should be_nil
    end
  end

  describe "deleting all data bag items in a data bag" do
    before(:each) do
      @databag.item.create(id: "one")
      @databag.item.create(id: "two")
    end

    it "returns the array of deleted data bag items" do
      @databag.item.delete_all.should each be_a(Ridley::DataBagItemResource)
    end

    it "removes all data bag items from the data bag" do
      @databag.item.delete_all

      @databag.item.all.should have(0).items
    end
  end

  describe "updating a data bag item" do
    before(:each) do
      @databag.item.create(id: "one")
    end

    it "returns the updated data bag item" do
      dbi = @databag.item.update(id: "one", name: "brooke")

      dbi[:name].should eql("brooke")
    end
  end

  describe "saving a data bag item" do
    context "when the data bag item exists" do
      before(:each) do
        @dbi = @databag.item.create(id: "ridley-test")
      end

      it "returns true if successful" do
        @dbi[:name] = "brooke"
        @dbi.save.should be_true
      end

      it "creates a new data bag item on the remote" do
        @dbi[:name] = "brooke"
        @dbi.save

        @databag.item.all.should have(1).item
      end
    end

    context "when the data bag item does not exist" do
      it "returns true if successful" do
        dbi = @databag.item.new

        dbi.attributes = { id: "not-there", name: "brooke" }
        dbi.save.should be_true
      end

      it "creates a new data bag item on the remote" do
        dbi = @databag.item.new
        dbi.attributes = { id: "not-there", name: "brooke" }
        dbi.save

        @databag.item.all.should have(1).item
      end
    end
  end
end
