require 'spec_helper'

describe Ridley::SandboxResource do
  let(:server_url) { "https://api.opscode.com/organizations/vialstudios" }
  let(:client_name) { "reset" }
  let(:client_key) { "/Users/reset/.chef/reset.pem" }

  let(:sandbox) do
    Ridley.new(
      server_url: server_url,
      client_name: client_name,
      client_key: client_key
    ).sandbox
  end

  before(:all) { WebMock.allow_net_connect! }
  after(:all) { WebMock.disable_net_connect! }

  describe "ClassMethods" do
    describe "::create" do
      let(:checksums) { Hash.new }

      before(:each) do
        stub_request(:post, File.join(server_url, "sandboxes")).
          with(body: MultiJson.encode(checksums: checksums)).
          to_return(status: 200, body: {
            uri: "https://api.opscode.com/organizations/vialstudios/sandboxes/bd091b150b0a4578b97771af6abf3e05",
            checksums: {},
            sandbox_id: "bd091b150b0a4578b97771af6abf3e05"
          })
      end

      subject { sandbox.create }

      it "returns a SandboxResource" do
        subject.should be_a(Ridley::SandboxResource)
      end

      it "has an empty Hash of checksums" do
        subject.checksums.should be_a(Hash)
        subject.checksums.should be_empty
      end

      it "has a value for 'uri'" do
        subject.uri.should eql("https://api.opscode.com/organizations/vialstudios/sandboxes/bd091b150b0a4578b97771af6abf3e05")
      end

      it "has a sandbox_id" do
        subject.sandbox_id.should eql("bd091b150b0a4578b97771af6abf3e05")
      end

      context "when given an array of checksums" do
        let(:checksums) do
          {
            "385ea5490c86570c7de71070bce9384a" => nil,
            "f6f73175e979bd90af6184ec277f760c" => nil,
            "2e03dd7e5b2e6c8eab1cf41ac61396d5" => nil
          }
        end
        let(:checksum_array) { checksums.keys }

        before(:each) do
          stub_request(:post, File.join(server_url, "sandboxes")).
            with(body: MultiJson.encode(checksums: checksums)).
            to_return(status: 200, body: {
              "uri" => "https://api.opscode.com/organizations/vialstudios/sandboxes/bd091b150b0a4578b97771af6abf3e05",
              "checksums" => {
                "385ea5490c86570c7de71070bce9384a" => {
                  "url" => "https://s3.amazonaws.com/opscode-platform-production-data/organization",
                  "needs_upload" => true
                },
                "f6f73175e979bd90af6184ec277f760c" => {
                  "url" => "https://s3.amazonaws.com/opscode-platform-production-data/organization",
                  "needs_upload" => true
                },
                "2e03dd7e5b2e6c8eab1cf41ac61396d5" => {
                  "url" => "https://s3.amazonaws.com/opscode-platform-production-data/organization",
                  "needs_upload" => true
                },
              },
              "sandbox_id" => "bd091b150b0a4578b97771af6abf3e05"
            })
        end

        subject { sandbox.create(checksum_array) }

        it "has a Hash of checksums with each of the given checksum ids" do
          subject.checksums.should have(checksum_array.length).checksums
        end
      end
    end
  end
end
