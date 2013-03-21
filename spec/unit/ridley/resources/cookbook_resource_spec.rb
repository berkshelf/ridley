require 'spec_helper'

describe Ridley::CookbookResource do
  let(:client) { double('client', connection: double('connection')) }

  subject { described_class.new(client) }

  describe "ClassMethods" do
    subject { described_class }
    let(:server_url) { "https://api.opscode.com/organizations/vialstudios" }
    let(:client_name) { "reset" }
    let(:client_key) { fixtures_path.join("reset.pem") }

    let(:client) do
      Ridley.new(
        server_url: server_url,
        client_name: client_name,
        client_key: client_key
      )
    end

    describe "::all" do
      subject { described_class.all(client) }

      before(:each) do
        stub_request(:get, File.join(server_url, "cookbooks")).
          to_return(status: 200, body: {
            "ant" => {
              "url" => "https://api.opscode.com/organizations/vialstudios/cookbooks/ant",
              "versions" => [ 
                {
                  "url" => "https://api.opscode.com/organizations/vialstudios/cookbooks/ant/0.10.1",
                  "version" => "0.10.1"
                }
              ]
            },
            "apache2" => {
              "url" => "https://api.opscode.com/organizations/vialstudios/cookbooks/apache2",
              "versions" => [
                {
                  "url" => "https://api.opscode.com/organizations/vialstudios/cookbooks/apache2/1.4.0",
                  "version" => "1.4.0"
                }
              ]
            }
          }
        )
      end

      it "returns a Hash" do
        subject.should be_a(Hash)
      end

      it "contains a key for each cookbook" do
        subject.should include("ant")
        subject.should include("apache2")
      end

      it "contains an array of versions for each cookbook" do
        subject["ant"].should be_a(Array)
        subject["ant"].should have(1).item
        subject["ant"].should include("0.10.1")
        subject["apache2"].should be_a(Array)
        subject["apache2"].should have(1).item
        subject["apache2"].should include("1.4.0")
      end
    end

    describe "::delete" do
      let(:name) { "ant" }
      let(:version) { "1.0.0" }

      it "sends a DELETE to the cookbook version URL" do
        stub_request(:delete, File.join(server_url, "cookbooks", name, version)).
          to_return(status: 200, body: {})

        described_class.delete(client, name, version)
      end

      context "when :purge is true" do
        it "appends ?purge=true to the end of the URL" do
          stub_request(:delete, File.join(server_url, "cookbooks", name, "#{version}?purge=true")).
            to_return(status: 200, body: {})

          described_class.delete(client, name, version, purge: true)
        end
      end
    end

    describe "::delete_all" do
      let(:name) { "ant" }
      let(:versions) { ["1.0.0", "1.2.0", "2.0.0"] }
      let(:options) { Hash.new }

      subject { described_class }

      it "deletes each version of the cookbook" do
        subject.should_receive(:versions).with(client, name).and_return(versions)

        versions.each do |version|
          subject.should_receive(:delete).with(client, name, version, options)
        end

        subject.delete_all(client, name, options)
      end
    end

    describe "::latest_version" do
      let(:name) { "ant" }
      subject { described_class }

      before(:each) do
        subject.should_receive(:versions).with(client, name).and_return(versions)
      end

      context "when the cookbook has no versions" do
        let(:versions) { Array.new }

        it "returns nil" do
          subject.latest_version(client, name).should be_nil
        end
      end

      context "when the cookbook has versions" do
        let(:versions) do
          [ "1.0.0", "1.2.0", "3.0.0", "1.4.1" ]
        end

        it "returns nil" do
          subject.latest_version(client, name).should eql("3.0.0")
        end
      end
    end

    describe "::versions" do
      let(:cookbook) { "artifact" }
      subject { described_class.versions(client, cookbook) }

      before(:each) do
        stub_request(:get, File.join(server_url, "cookbooks", cookbook)).
          to_return(status: 200, body: {
            cookbook => {
              "versions" => [
                {
                  "url" => "https://api.opscode.com/organizations/ridley/cookbooks/artifact/1.0.0",
                  "version" => "1.0.0"
                },
                {
                  "url" => "https://api.opscode.com/organizations/ridley/cookbooks/artifact/1.1.0",
                  "version" => "1.1.0"
                },
                {
                  "url" => "https://api.opscode.com/organizations/ridley/cookbooks/artifact/1.2.0",
                  "version" => "1.2.0"
                }
              ],
              "url" => "https://api.opscode.com/organizations/ridley/cookbooks/artifact"}
            }
          )
      end

      it "returns an array" do
        subject.should be_a(Array)
      end

      it "contains a version string for each cookbook version available" do
        subject.should have(3).versions
        subject.should include("1.0.0")
        subject.should include("1.1.0")
        subject.should include("1.2.0")
      end
    end

    describe "::upload" do
      pending
    end

    describe "::update" do
      pending
    end
  end

  describe "#download" do
    it "downloads each file" do
      subject.stub(:manifest) do
        {
          resources: [],
          providers: [],
          recipes: [
            {
              checksum: "aa3505d3eb8ce328ea84a4333df05b07",
              name: "default.rb",
              path: "recipes/default.rb",
              specificity: "default",
              url: "https://chef.lax1.riotgames.com/organizations/reset/cookbooks/ohai/1.0.2/files/aa3505d3eb8ce328ea84a4333df05b07"
            }
          ],
          definitions: [],
          libraries: [],
          attributes: [],
          files: [
            {
              checksum: "85bc3bb921efade3f2566a668ab4b639",
              name: "README",
              path: "files/default/plugins/README",
              specificity: "plugins",
              url: "https://chef.lax1.riotgames.com/organizations/reset/cookbooks/ohai/1.0.2/files/85bc3bb921efade3f2566a668ab4b639"
            }
          ],
          templates: [],
          root_files: []
        }
      end

      subject.should_receive(:download_file).with(:recipes, "recipes/default.rb", anything)
      subject.should_receive(:download_file).with(:files, "files/default/plugins/README", anything)

      subject.download
    end
  end

  describe "#download_file" do
    let(:destination) { tmp_path.join('fake.file').to_s }

    before(:each) do
      subject.stub(:root_files) { [ { path: 'metadata.rb', url: "http://test.it/file" } ] }
    end

    it "downloads the file from the file's url" do
      client.connection.should_receive(:stream).with("http://test.it/file", destination)

      subject.download_file(:root_file, "metadata.rb", destination)
    end

    context "when given an unknown filetype" do
      it "raises an UnknownCookbookFileType error" do
        expect {
          subject.download_file(:not_existant, "default.rb", destination)
        }.to raise_error(Ridley::Errors::UnknownCookbookFileType)
      end
    end

    context "when the cookbook doesn't have the specified file" do
      before(:each) do
        subject.stub(:root_files) { Array.new }
      end

      it "returns nil" do
        subject.download_file(:root_file, "metadata.rb", destination).should be_nil
      end
    end
  end

  describe "#manifest" do
    it "returns a Hash" do
      subject.manifest.should be_a(Hash)
    end

    it "has a key for each item in FILE_TYPES" do
      subject.manifest.keys.should =~ described_class::FILE_TYPES
    end

    it "contains an empty array for each key" do
      subject.manifest.should each be_a(Array)
      subject.manifest.values.should each be_empty
    end
  end
end
