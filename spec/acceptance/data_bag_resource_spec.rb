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

  before(:each) do
    connection.data_bag.delete_all
  end

  describe "listing data bags" do
    context "when no data bags exist" do
      it "returns an empty array" do
        connection.data_bag.all.should have(0).items
      end
    end

    context "when the server has data bags" do
      before(:each) do
        connection.data_bag.create(name: "ridley-one")
        connection.data_bag.create(name: "ridley-two")
      end

      it "returns an array of data bags" do
        connection.data_bag.all.should each be_a(Ridley::DataBagResource)
      end

      it "returns all of the data bags on the server" do
        connection.data_bag.all.should have(2).items
      end
    end
  end

  describe "creating a data bag" do
    pending
  end
end
