require 'spec_helper'

describe Ridley::SandboxObject do
  let(:resource) { double('chef-resource') }

  subject do
    described_class.new(double('registry'),
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

  before { allow(subject).to receive_messages(resource: resource) }

  describe "#checksums" do
    skip
  end

  describe "#commit" do
    let(:response) { { is_completed: nil} }
    before { expect(resource).to receive(:commit).with(subject).and_return(response) }

    context "when the commit is successful" do
      before { response[:is_completed] = true }

      it "has an 'is_completed' value of true" do
        subject.commit

        expect(subject.is_completed).to be_truthy
      end
    end

    context "when the commit is a failure" do
      before { response[:is_completed] = false }

      it "has an 'is_completed' value of false" do
        subject.commit

        expect(subject.is_completed).to be_falsey
      end
    end
  end

  describe "#upload" do
    it "delegates to resource#upload" do
      checksums = double('checksums')
      expect(resource).to receive(:upload).with(subject, checksums)

      subject.upload(checksums)
    end
  end
end
