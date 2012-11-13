require 'spec_helper'

describe Ridley::Bootstrapper::Context do
  let(:host) { "reset.riotgames.com" }

  let(:options) do
    {
      server_url: "https://api.opscode.com/organizations/vialstudios",
      validator_client: "chef-validator",
      validator_path: fixtures_path.join("reset.pem").to_s,
      encrypted_data_bag_secret_path: fixtures_path.join("reset.pem").to_s
    }
  end

  describe "ClassMethods" do
    subject { Ridley::Bootstrapper::Context }

    describe "::new" do
      it "sets a default value of 'true' to 'sudo'" do
        options.delete(:sudo)
        obj = subject.new(host, options)

        obj.send(:sudo).should be_true
      end

      it "sets the value of sudo to 'false' if provided" do
        options.merge!(sudo: false)
        obj = subject.new(host, options)

        obj.send(:sudo).should be_false
      end

      context "when validator_path is not specified" do
        let(:options) { Hash.new }

        it "raises an ArgumentError" do
          lambda {
            subject.new(host, options)
          }.should raise_error(Ridley::Errors::ArgumentError)
        end
      end

      context "when a validator_path is specified" do
        let(:options) do
          {
            server_url: "https://api.opscode.com/organizations/vialstudios",
            validator_path: fixtures_path.join("reset.pem").to_s
          }
        end

        it "sets a value for validation_key" do
          subject.new(host, options).validation_key.should_not be_nil
        end
      end
    end
  end

  subject { Ridley::Bootstrapper::Context.new(host, options) }

  describe "#boot_command" do
    it "returns a string" do
      subject.boot_command.should be_a(String)
    end
  end

  describe "#chef_run" do
    it "returns a string" do
      subject.chef_run.should be_a(String)
    end
  end

  describe "#chef_config" do
    it "returns a string" do
      subject.chef_config.should be_a(String)
    end
  end

  describe "#first_boot" do
    it "returns a string" do
      subject.first_boot.should be_a(String)
    end
  end

  describe "#validation_key" do
    it "returns a string" do
      subject.validation_key.should be_a(String)
    end

    it "returns the chomped contents of the file found at validator_path" do
      subject.validation_key.should eql(File.read(options[:validator_path]).chomp)
    end

    context "when a validator file is not found at validator_path" do
      before(:each) do
        subject.stub(:validator_path) { fixtures_path.join("not.txt").to_s }
      end

      it "raises a ValidatorNotFound error" do
        lambda {
          subject.validation_key
        }.should raise_error(Ridley::Errors::ValidatorNotFound)
      end
    end
  end

  describe "#encrypted_data_bag_secret" do
    it "returns a string" do
      subject.encrypted_data_bag_secret.should be_a(String)
    end

    context "when a encrypted_data_bag_secret_path is not provided" do
      before(:each) do
        subject.stub(:encrypted_data_bag_secret_path) { nil }
      end

      it "returns nil" do
        subject.encrypted_data_bag_secret.should be_nil
      end
    end

    context "when the file is not found at the given encrypted_data_bag_secret_path" do
      before(:each) do
        subject.stub(:encrypted_data_bag_secret_path) { fixtures_path.join("not.txt").to_s }
      end

      it "raises an EncryptedDataBagSecretNotFound erorr" do
        lambda {
          subject.encrypted_data_bag_secret
        }.should raise_error(Ridley::Errors::EncryptedDataBagSecretNotFound)
      end
    end
  end
end
