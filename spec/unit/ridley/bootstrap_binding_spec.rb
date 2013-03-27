require 'spec_helper'

describe Ridley::BootstrapBinding do
  let(:host) { "reset.riotgames.com" }

  describe "ClassMethods" do
    subject { Ridley::BootstrapBinding }

    context "when server_url is not specified" do
      let(:options) { Hash.new }

      it "raises an ArgumentError" do
        expect {
          subject.validate_options(options)
        }.to raise_error(Ridley::Errors::ArgumentError)
      end
    end

    context "when validator_path is not specified" do
      let(:options) do
        {
          server_url: "https://api.opscode.com/organizations/vialstudios"
        }
      end

      it "raises an ArgumentError" do
        expect {
          subject.validate_options(options)
        }.to raise_error(Ridley::Errors::ArgumentError)
      end
    end
  end

  subject { Ridley::BootstrapBinding.new }

  describe "#templates_path" do
    it "returns a pathname" do
      subject.templates_path.should be_a(Pathname)
    end
  end
end
