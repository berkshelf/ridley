require 'spec_helper'

describe Ridley::SandboxUploader do
  let(:client_name) { "reset" }
  let(:client_key) { fixtures_path.join('reset.pem') }
  let(:connection) do
    double('connection',
      client_name: client_name,
      client_key: client_key,
      options: {}
    )
  end
  let(:resource) { double('resource', connection: connection) }
  let(:checksums) do
    {
      "oGCPHrQ+5MylEL+V+NIJ9w==" => {
        needs_upload: true,
        url: "https://api.opscode.com/organizations/vialstudios/sandboxes/bd091b150b0a4578b97771af6abf3e05"
      }
    }
  end

  let(:sandbox) { Ridley::SandboxObject.new(resource, checksums: checksums) }

  describe "ClassMethods" do
    subject { described_class }

    describe "::checksum" do
      subject { described_class.checksum(path) }

      let(:path) { fixtures_path.join('reset.pem') }

      it { should eq("a0608f1eb43ee4cca510bf95f8d209f7") }
    end

    describe "::checksum64" do
      subject { described_class.checksum64(path) }

      let(:path) { fixtures_path.join('reset.pem') }

      it { should eq("oGCPHrQ+5MylEL+V+NIJ9w==") }
    end

    describe "::checksum64_string" do
      it "returns the same as ::checksum64" do
        subject.checksum64_string(File.read(fixtures_path.join('reset.pem'))).should == subject.checksum64(fixtures_path.join('reset.pem'))
      end
    end

  end

  subject { described_class.new(client_name, client_key, {}) }

  describe "#upload" do
    let(:chk_id) { "a0608f1eb43ee4cca510bf95f8d209f7" }
    let(:path) { fixtures_path.join('reset.pem').to_s }
    let(:different_path) { fixtures_path.join('recipe_one.rb').to_s }

    before do
      connection.stub(foss?: false)
    end

    context "when the checksum needs uploading" do
      let(:checksums) do
        {
          chk_id => {
            url: "https://api.opscode.com/organizations/vialstudios/sandboxes/bd091b150b0a4578b97771af6abf3e05",
            needs_upload: true
          }
        }
      end

      it "uploads each checksum to their target URL" do
        stub_request(:put, checksums[chk_id][:url])

        subject.upload(sandbox, chk_id, path)
      end

      it "refuses to upload a wrong file" do
        expect{ subject.upload(sandbox, chk_id, different_path) }.to raise_error(Ridley::Errors::ArgumentError)
      end
    end

    context "when the checksum doesn't need uploading" do
      let(:checksums) do
        {
          chk_id => {
            needs_upload: false
          }
        }
      end

      let(:sandbox) do
        Ridley::SandboxObject.new(double, checksums: checksums)
      end

      it "returns nil" do
        subject.upload(sandbox, chk_id, path).should be_nil
      end
    end

    context "when the connection is an open source server connection with a non-80 port" do
      before do
        connection.stub(foss?: true, server_url: "http://localhost:8889")
      end

      let(:checksums) do
        {
          chk_id => {
            url: "http://localhost/sandboxes/bd091b150b0a4578b97771af6abf3e05",
            needs_upload: true
          }
        }
      end

      it "does not strip the port from the target to upload to" do
        stub_request(:put, "http://localhost:8889/sandboxes/bd091b150b0a4578b97771af6abf3e05")

        subject.upload(sandbox, chk_id, path)
      end
    end

    context "when the checksum is passed with an IO" do

      let(:chk_id){ 'b53227da4280f0e18270f21dd77c91d0' }

      let(:checksums) do
        {
          chk_id => {
            url: "https://api.opscode.com/organizations/vialstudios/sandboxes/bd091b150b0a4578b97771af6abf3e05",
            needs_upload: true
          }
        }
      end

      let(:sandbox) { Ridley::SandboxObject.new(resource, checksums: checksums) }

      it "accepts something that responds to read" do
        stub_request(:put, checksums[chk_id][:url])
        io = double("io")
        io.should_receive(:read).once.and_return("Some content")
        subject.upload(sandbox, chk_id, io)
      end

      it "refuses uploading something with a wrong checksum" do
        io = double("io")
        io.should_receive(:read).once.and_return("A different content")
        expect{ subject.upload(sandbox, chk_id, io) }.to raise_error(Ridley::Errors::ArgumentError)
      end

    end

  end
end
