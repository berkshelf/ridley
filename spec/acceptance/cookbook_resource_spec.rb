require 'spec_helper'

describe "Cookbook API operations", type: "acceptance" do
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

  describe "finding a cookbook" do
    pending
  end

  describe "listing all cookbooks" do
    it "should return an array of environment objects" do
      connection.cookbook.all.should each be_a(Ridley::CookbookResource)
    end
  end
end
