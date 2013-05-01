require 'spec_helper'

describe "DataBag API operations", type: "acceptance" do
  let(:server_url)  { Ridley::RSpec::ChefServer.server_url }
  let(:client_name) { "reset" }
  let(:client_key)  { fixtures_path.join('reset.pem').to_s }
  let(:connection)  { Ridley.new(server_url: server_url, client_name: client_name, client_key: client_key) }

  describe "listing data bags" do
    context "when no data bags exist" do
      it "returns an empty array" do
        connection.data_bag.all.should have(0).items
      end
    end

    context "when the server has data bags" do
      before do
        chef_data_bag("ridley-one")
        chef_data_bag("ridley-two")
      end

      it "returns an array of data bags" do
        connection.data_bag.all.should each be_a(Ridley::DataBagObject)
      end

      it "returns all of the data bags on the server" do
        connection.data_bag.all.should have(2).items
      end
    end
  end

  describe "creating a data bag" do
    it "returns a Ridley::DataBagObject" do
      connection.data_bag.create(name: "ridley-one").should be_a(Ridley::DataBagObject)
    end
  end
end
