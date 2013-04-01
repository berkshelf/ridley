require 'spec_helper'

describe Ridley::BootstrapBinding do
  let(:host) { "reset.riotgames.com" }
  let(:options) do
    {
      server_url: "https://api.opscode.com/organizations/vialstudios",
      validator_client: "chef-validator",
      validator_path: fixtures_path.join("reset.pem").to_s,
      encrypted_data_bag_secret_path: fixtures_path.join("reset.pem").to_s,
      chef_version: "11.4.0"
    }
  end

  describe "ClassMethods" do
    subject { Ridley::BootstrapBinding }

    describe ":validate_options" do
      context "when server_url is not specified" do
        let(:options) { Hash.new }

        it "raises an ArgumentError" do
          expect {
            subject.validate_options(options)
          }.to raise_error(Ridley::Errors::ArgumentError)
        end
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
end
