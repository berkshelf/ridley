require 'spec_helper'

describe "Environment API operations" do
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

  before(:all) do
    WebMock.allow_net_connect!
  end

  after(:all) do
    WebMock.disable_net_connect!
  end

  describe "finding a cookbook" do
    pending
  end

  describe "creating a cookbook" do
    pending
  end

  describe "deleting a cookbook" do
    pending
  end

  describe "deleting all cookbooks" do
    pending
  end

  describe "listing all cookbooks" do
    it "should return an array of environment objects" do
      connection.start do
        cookbook.all.should each be_a(Ridley::Cookbook)
      end
    end
  end

  describe "updating a cookbook" do
    pending
  end
end
