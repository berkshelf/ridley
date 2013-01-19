require 'spec_helper'

describe Ridley::SandboxResource do
  let(:server_url) { "https://api.opscode.com/organizations/vialstudios" }
  let(:client_name) { "reset" }
  let(:client_key) { fixtures_path.join("reset.pem") }

  let(:sandbox) do
    Ridley.new(
      server_url: server_url,
      client_name: client_name,
      client_key: client_key
    ).sandbox
  end

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

      it "has an 'is_completed' value of false" do
        subject.is_completed.should be_false
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

  subject do
    sandbox.new(
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
    )
  end

  describe "#commit" do
    context "on successful commit" do
      before(:each) do
        stub_request(:put, File.join(server_url, "sandboxes", "bd091b150b0a4578b97771af6abf3e05")).
          with(body: MultiJson.encode(is_completed: true)).
          to_return(status: 200, body: {
            is_completed: true,
            _rev: "1-bbc8a96f7486aeba2b562d382142fd68",
            create_time: "2013-01-16T01:43:43+00:00",
            guid: "bd091b150b0a4578b97771af6abf3e05",
            json_class: "Chef::Sandbox",
            name: "bd091b150b0a4578b97771af6abf3e05",
            checksums: [],
            chef_type: "sandbox"
          })
      end

      it "has an 'is_completed' value of true" do
        subject.commit

        subject.is_completed.should be_true
      end
    end

    context "on commit failure" do
      before(:each) do
        stub_request(:put, File.join(server_url, "sandboxes", "bd091b150b0a4578b97771af6abf3e05")).
          with(body: MultiJson.encode(is_completed: true)).
          to_return(status: 200, body: {
            is_completed: false,
            _rev: "1-bbc8a96f7486aeba2b562d382142fd68",
            create_time: "2013-01-16T01:43:43+00:00",
            guid: "bd091b150b0a4578b97771af6abf3e05",
            json_class: "Chef::Sandbox",
            name: "bd091b150b0a4578b97771af6abf3e05",
            checksums: [],
            chef_type: "sandbox"
          })
      end

      it "has an 'is_completed' value of false" do
        subject.commit

        subject.is_completed.should be_false
      end
    end
  end

  describe "#upload" do
    it "delegates self to SandboxUploader.upload" do
      checksums = double('checksums')
      Ridley::SandboxUploader.should_receive(:upload).with(subject, checksums)

      subject.upload(checksums)
    end
  end
end
