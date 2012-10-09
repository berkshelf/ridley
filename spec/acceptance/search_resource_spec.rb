require 'spec_helper'

describe "Search API operations", type: "acceptance" do
  let(:server_url) { "https://api.opscode.com" }
  let(:client_name) { "reset" }
  let(:client_key) { "/Users/reset/.chef/reset.pem" }
  let(:organization) { "ridley" }

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

  describe "listing indexes" do
    it "returns an array of indexes" do
      indexes = connection.search_indexes

      indexes.should include(:role)
      indexes.should include(:node)
      indexes.should include(:client)
    end
  end

  describe "searching an index that doesn't exist" do
    it "it raises a Ridley::Errors::HTTPNotFound error" do
      lambda {
        connection.search(:notthere)
      }.should raise_error(Ridley::Errors::HTTPNotFound)
    end
  end
end
