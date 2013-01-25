require 'spec_helper'

describe Ridley::CookbookResource do
  let(:client) { double('client', connection: double('connection')) }

  subject { described_class.new(client) }

  describe "ClassMethods" do
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
  end

  describe "#download_file" do
    let(:destination) { tmp_path.join('fake.file') }

    before(:each) do
      subject.stub(:root_files) { [ { name: 'metadata.rb', url: "http://test.it/file" } ] }
    end

    it "downloads the file from the file's url" do
      client.connection.should_receive(:stream).with("http://test.it/file", destination)

      subject.download_file(:root_file, "metadata.rb", destination)
    end

    context "when given 'attribute' for filetype" do
      it "raises an InternalError" do
        expect {
          subject.download_file(:attribute, "default.rb", destination)
        }.to raise_error(Ridley::Errors::InternalError)
      end
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
end
