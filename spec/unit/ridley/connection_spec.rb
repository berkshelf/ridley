require 'spec_helper'

describe Ridley::Connection do
  let(:server_url) { "https://api.opscode.com" }
  let(:client_name) { "reset" }
  let(:client_key) { fixtures_path.join("reset.pem").to_s }

  subject do
    described_class.new(server_url, client_name, client_key)
  end

  describe "configurable retries" do
    before(:each) do
      stub_request(:get, "https://api.opscode.com/organizations/vialstudios").to_return(status: 500, body: "")
    end

    it "attempts five (5) retries by default" do
      expect {
        subject.get('organizations/vialstudios')
      }.to raise_error(Ridley::Errors::HTTPInternalServerError)
      expect(a_request(:get, "https://api.opscode.com/organizations/vialstudios")).to have_been_made.times(6)
    end

    context "given a configured count of two (2) retries" do
      subject do
        described_class.new(server_url, client_name, client_key, retries: 2)
      end

      it "attempts two (2) retries" do
        expect {
          subject.get('organizations/vialstudios')
        }.to raise_error(Ridley::Errors::HTTPInternalServerError)

        expect(a_request(:get, "https://api.opscode.com/organizations/vialstudios")).to have_been_made.times(3)
      end
    end
  end

  describe "#api_type" do
    it "returns :foss if the organization is not set" do
      subject.stub(:organization).and_return(nil)

      expect(subject.api_type).to eql(:foss)
    end

    it "returns :hosted if the organization is set" do
      subject.stub(:organization).and_return("vialstudios")

      expect(subject.api_type).to eql(:hosted)
    end
  end

  describe "#stream" do
    let(:target) { "http://test.it/file" }
    let(:destination) { tmp_path.join("test.file") }
    let(:contents) { "SOME STRING STUFF\nHERE.\n" }

    before(:each) do
      stub_request(:get, "http://test.it/file").to_return(status: 200, body: contents)
    end

    it "creates a destination file on disk" do
      subject.stream(target, destination)

      expect(File.exist?(destination)).to be_truthy
    end

    it "returns true when the file was copied" do
      expect(subject.stream(target, destination)).to be_truthy
    end

    it "contains the contents of the response body" do
      subject.stream(target, destination)

      expect(File.read(destination)).to include(contents)
    end
  end
end
