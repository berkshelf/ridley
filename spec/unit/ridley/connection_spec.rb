require 'spec_helper'

describe Ridley::Connection do
  let(:server_url) { "https://api.opscode.com" }
  let(:client_name) { "reset" }
  let(:client_key) { fixtures_path.join("reset.pem").to_s }

  subject do
    described_class.new(server_url, client_name, client_key)
  end

  describe "#api_type" do
    it "returns :foss if the organization is not set" do
      subject.stub(:organization).and_return(nil)

      subject.api_type.should eql(:foss)
    end

    it "returns :hosted if the organization is set" do
      subject.stub(:organization).and_return("vialstudios")

      subject.api_type.should eql(:hosted)
    end
  end

  describe "#stream" do
    let(:target) { "http://test.it/file" }
    let(:destination) { tmp_path.join("test.file") }
    let(:contents) { "SOME STRING STUFF\nHERE.\n" }

    before(:each) do
      stub_request(:get, "http://test.it/file").
        to_return(status: 200, body: contents)
    end

    it "creates a destination file on disk" do
      subject.stream(target, destination)

      File.exist?(destination).should be_true
    end

    it "contains the contents of the response body" do
      subject.stream(target, destination)

      File.read(destination).should include(contents)
    end
  end
end
