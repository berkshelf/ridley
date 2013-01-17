require 'spec_helper'

describe "Sandbox API operations", type: "acceptance" do
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

  let(:checksums) do
    [
      Ridley::SandboxUploader.checksum(fixtures_path.join("recipe_one.rb")),
      Ridley::SandboxUploader.checksum(fixtures_path.join("recipe_two.rb"))
    ]
  end

  describe "creating a new sandbox" do
    it "returns an instance of Ridley::SandboxResource" do
      connection.sandbox.create(checksums).should be_a(Ridley::SandboxResource)
    end

    it "contains a value for sandbox_id" do
      connection.sandbox.create(checksums).sandbox_id.should_not be_nil
    end

    it "returns an instance with the same amount of checksums given to create" do
      connection.sandbox.create(checksums).checksums.should have(2).items
    end
  end
end
