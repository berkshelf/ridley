require 'spec_helper'

describe "Sandbox API operations", type: "acceptance" do
  let(:server_url)  { Ridley::RSpec::ChefServer.server_url }
  let(:client_name) { "reset" }
  let(:client_key)  { fixtures_path.join('reset.pem').to_s }
  let(:connection)  { Ridley.new(server_url: server_url, client_name: client_name, client_key: client_key) }

  let(:checksums) do
    [
      Ridley::SandboxUploader.checksum(File.open(fixtures_path.join("recipe_one.rb"))),
      Ridley::SandboxUploader.checksum(File.open(fixtures_path.join("recipe_two.rb")))
    ]
  end

  describe "creating a new sandbox" do
    it "returns an instance of Ridley::SandboxObject" do
      connection.sandbox.create(checksums).should be_a(Ridley::SandboxObject)
    end

    it "contains a value for sandbox_id" do
      connection.sandbox.create(checksums).sandbox_id.should_not be_nil
    end

    it "returns an instance with the same amount of checksums given to create" do
      connection.sandbox.create(checksums).checksums.should have(2).items
    end
  end
end
