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
end
