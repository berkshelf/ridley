require 'spec_helper'

describe "DataBag API operations", type: "acceptance" do
  let(:server_url)  { Ridley::RSpec::ChefServer.server_url }
  let(:client_name) { "reset" }
  let(:client_key)  { fixtures_path.join('reset.pem').to_s }
  let(:connection)  { Ridley.new(server_url: server_url, client_name: client_name, client_key: client_key) }

  let(:data_bag) do
    chef_data_bag("ridley-test")
    connection.data_bag.find("ridley-test")
  end

  describe "listing data bag items" do
    context "when the data bag has no items" do
      it "returns an empty array" do
        data_bag.item.all.should have(0).items
      end
    end

    context "when the data bag has items" do
      before(:each) do
        data_bag.item.create(id: "one")
        data_bag.item.create(id: "two")
      end

      it "returns an array with each item" do
        data_bag.item.all.should have(2).items
      end
    end
  end

  describe "creating a data bag item" do
    it "adds a data bag item to the collection of data bag items" do
      data_bag.item.create(id: "appconfig", host: "host.local", port: 80, admin: false, servers: ["one"])

      data_bag.item.all.should have(1).item
    end

    context "when an 'id' field is missing" do
      it "raises an Ridley::Errors::InvalidResource error" do
        expect {
          data_bag.item.create(name: "jamie")
        }.to raise_error(Ridley::Errors::InvalidResource)
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
      data_bag.item.create(attributes)

      data_bag.item.find("appconfig").to_hash.should eql(attributes)
    end
  end

  describe "deleting a data bag item" do
    let(:attributes) do
      {
        "id" => "appconfig",
        "host" => "host.local"
      }
    end

    before { data_bag.item.create(attributes) }

    it "returns the deleted data bag item" do
      dbi = data_bag.item.delete(attributes["id"])

      dbi.should be_a(Ridley::DataBagItemObject)
      dbi.attributes.should eql(attributes)
    end

    it "deletes the data bag item from the server" do
      data_bag.item.delete(attributes["id"])

      data_bag.item.find(attributes["id"]).should be_nil
    end
  end

  describe "deleting all data bag items in a data bag" do
    before do
      data_bag.item.create(id: "one")
      data_bag.item.create(id: "two")
    end

    it "returns the array of deleted data bag items" do
      data_bag.item.delete_all.should each be_a(Ridley::DataBagItemObject)
    end

    it "removes all data bag items from the data bag" do
      data_bag.item.delete_all

      data_bag.item.all.should have(0).items
    end
  end

  describe "updating a data bag item" do
    before { data_bag.item.create(id: "one") }

    it "returns the updated data bag item" do
      dbi = data_bag.item.update(id: "one", name: "brooke")

      dbi[:name].should eql("brooke")
    end
  end

  describe "saving a data bag item" do
    context "when the data bag item exists" do
      let(:dbi) { data_bag.item.create(id: "ridley-test") }

      it "returns true if successful" do
        dbi[:name] = "brooke"
        dbi.save.should be_true
      end

      it "creates a new data bag item on the remote" do
        dbi[:name] = "brooke"
        dbi.save

        data_bag.item.all.should have(1).item
      end
    end

    context "when the data bag item does not exist" do
      it "returns true if successful" do
        dbi = data_bag.item.new

        dbi.attributes = { id: "not-there", name: "brooke" }
        dbi.save.should be_true
      end

      it "creates a new data bag item on the remote" do
        dbi = data_bag.item.new
        dbi.attributes = { id: "not-there", name: "brooke" }
        dbi.save

        data_bag.item.all.should have(1).item
      end
    end
  end
end
