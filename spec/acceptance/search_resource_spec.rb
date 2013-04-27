require 'spec_helper'

describe "Search API operations", type: "acceptance" do
  let(:server_url)  { Ridley::RSpec::ChefServer.server_url }
  let(:client_name) { "reset" }
  let(:client_key)  { fixtures_path.join('reset.pem').to_s }
  let(:connection)  { Ridley.new(server_url: server_url, client_name: client_name, client_key: client_key) }

  describe "listing indexes" do
    it "returns an array of indexes" do
      indexes = connection.search_indexes

      indexes.should include("role")
      indexes.should include("node")
      indexes.should include("client")
      indexes.should include("environment")
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
