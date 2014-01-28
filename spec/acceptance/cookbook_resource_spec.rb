require 'spec_helper'

describe "Client API operations", type: "acceptance" do
  let(:server_url)  { Ridley::RSpec::ChefServer.server_url }
  let(:client_name) { "reset" }
  let(:client_key)  { fixtures_path.join('reset.pem').to_s }
  let(:connection)  { Ridley.new(server_url: server_url, client_name: client_name, client_key: client_key) }

  subject { connection.cookbook }

  describe "downloading a cookbook" do
    before { subject.upload(fixtures_path.join('example_cookbook')) }
    let(:name) { "example_cookbook" }
    let(:version) { "0.1.0" }
    let(:destination) { tmp_path.join("example_cookbook-0.1.0") }

    context "when the cookbook of the name/version is found" do
      before { subject.download(name, version, destination) }

      it "downloads the cookbook to the destination" do
        expect(File.exist?(destination.join("metadata.json"))).to be_true
      end
    end
  end

  describe "uploading a cookbook" do
    let(:path) { fixtures_path.join("example_cookbook") }

    it "uploads the entire contents of the cookbook in the given path, applying chefignore" do
      subject.upload(path)
      cookbook = subject.find("example_cookbook", "0.1.0")

      cookbook.attributes.should have(1).item
      cookbook.definitions.should have(1).item
      cookbook.files.should have(2).items
      cookbook.libraries.should have(1).item
      cookbook.providers.should have(1).item
      cookbook.recipes.should have(1).item
      cookbook.resources.should have(1).item
      cookbook.templates.should have(1).item
      cookbook.root_files.should have(1).items
    end

    it "does not contain a raw metadata.rb but does contain a compiled metadata.json" do
      subject.upload(path)
      cookbook = subject.find("example_cookbook", "0.1.0")

      expect(cookbook.root_files.any? { |f| f[:name] == "metadata.json" }).to be_true
      expect(cookbook.root_files.any? { |f| f[:name] == "metadata.rb" }).to be_false
    end
  end

  describe "listing cookbooks" do
    before do
      chef_cookbook("ruby", "1.0.0")
      chef_cookbook("ruby", "2.0.0")
      chef_cookbook("elixir", "3.0.0")
      chef_cookbook("elixir", "3.0.1")
    end

    it "returns all of the cookbooks on the server" do
      all_cookbooks = subject.all
      expect(all_cookbooks).to have(2).items
      expect(all_cookbooks["ruby"]).to have(2).items
      expect(all_cookbooks["elixir"]).to have(2).items
    end
  end
end
