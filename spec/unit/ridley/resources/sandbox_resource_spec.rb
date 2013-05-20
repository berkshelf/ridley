require 'spec_helper'

describe Ridley::SandboxResource do
  let(:client_name) { "reset" }
  let(:client_key) { fixtures_path.join('reset.pem') }
  let(:connection) { double('chef-connection') }
  subject { described_class.new(double, client_name, client_key) }
  before  { subject.stub(connection: connection) }

  describe "#create" do
    let(:sandbox_id) { "bd091b150b0a4578b97771af6abf3e05" }
    let(:sandbox_uri) { "https://api.opscode.com/organizations/vialstudios/sandboxes/bd091b150b0a4578b97771af6abf3e05" }
    let(:checksums) { Hash.new }
    let(:response) do
      double(body: { uri: sandbox_uri, checksums: checksums, sandbox_id: sandbox_id })
    end

    before(:each) do
      connection.stub(:post).
        with(subject.class.resource_path, JSON.fast_generate(checksums: checksums)).
        and_return(response)
    end

    it "returns a Ridley::SandboxObject" do
      subject.create.should be_a(Ridley::SandboxObject)
    end

    it "has a value of 'false' for :is_completed" do
      subject.create.is_completed.should be_false
    end

    it "has an empty Hash of checksums" do
      subject.create.checksums.should be_a(Hash)
      subject.create.checksums.should be_empty
    end

    it "has a value for :uri" do
      subject.create.uri.should eql(sandbox_uri)
    end

    it "has a value for :sandbox_id" do
      subject.create.sandbox_id.should eql(sandbox_id)
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

      it "has a Hash of checksums with each of the given checksum ids" do
        subject.create(checksum_array).checksums.should have(checksum_array.length).checksums
      end
    end
  end

  describe "#commit" do
    let(:sandbox_id) { "bd091b150b0a4578b97771af6abf3e05" }
    let(:sandbox_path) { "#{described_class.resource_path}/#{sandbox_id}" }

    let(:response) do
      double(body: {
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

    it "sends a /PUT to the sandbox resource with is_complete set to true" do
      connection.should_receive(:put).with(sandbox_path, JSON.fast_generate(is_completed: true)).and_return(response)

      subject.commit(sandbox_id)
    end

    context "when a sandbox of the given ID is not found" do
      before do
        connection.should_receive(:put).and_raise(Ridley::Errors::HTTPNotFound.new({}))
      end

      it "raises a ResourceNotFound error" do
        expect {
          subject.commit(sandbox_id)
        }.to raise_error(Ridley::Errors::ResourceNotFound)
      end
    end

    context "when the given sandbox contents are malformed" do
      before do
        connection.should_receive(:put).and_raise(Ridley::Errors::HTTPBadRequest.new({}))
      end

      it "raises a SandboxCommitError error" do
        expect {
          subject.commit(sandbox_id)
        }.to raise_error(Ridley::Errors::SandboxCommitError)
      end
    end

    context "when the user who made the request is not authorized" do
      it "raises a PermissionDenied error on unauthorized" do
        connection.should_receive(:put).and_raise(Ridley::Errors::HTTPUnauthorized.new({}))

        expect {
          subject.commit(sandbox_id)
        }.to raise_error(Ridley::Errors::PermissionDenied)
      end

      it "raises a PermissionDenied error on forbidden" do
        connection.should_receive(:put).and_raise(Ridley::Errors::HTTPForbidden.new({}))

        expect {
          subject.commit(sandbox_id)
        }.to raise_error(Ridley::Errors::PermissionDenied)
      end
    end
  end

  describe "#update" do
    it "is not a supported action" do
      expect {
        subject.update(anything)
      }.to raise_error(RuntimeError, "action not supported")
    end
  end

  describe "#update" do
    it "is not a supported action" do
      expect {
        subject.update
      }.to raise_error(RuntimeError, "action not supported")
    end
  end

  describe "#all" do
    it "is not a supported action" do
      expect {
        subject.all
      }.to raise_error(RuntimeError, "action not supported")
    end
  end

  describe "#find" do
    it "is not a supported action" do
      expect {
        subject.find
      }.to raise_error(RuntimeError, "action not supported")
    end
  end

  describe "#delete" do
    it "is not a supported action" do
      expect {
        subject.delete
      }.to raise_error(RuntimeError, "action not supported")
    end
  end

  describe "#delete_all" do
    it "is not a supported action" do
      expect {
        subject.delete_all
      }.to raise_error(RuntimeError, "action not supported")
    end
  end
end
