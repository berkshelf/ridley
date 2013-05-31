require 'spec_helper'

describe Ridley::BootstrapContext::Unix do
  let(:options) do
    {
      server_url: "https://api.opscode.com/organizations/vialstudios",
      validator_client: "chef-validator",
      validator_path: fixtures_path.join("reset.pem").to_s,
      encrypted_data_bag_secret: File.read(fixtures_path.join("reset.pem"))
    }
  end

  describe "ClassMethods" do
    subject { described_class }

    describe "::new" do
      context "when no sudo option is passed through" do
        it "sets a default value of 'true' to 'sudo'" do
          options.delete(:sudo)
          obj = subject.new(options)

          obj.send(:sudo).should be_true
        end
      end

      context "when the sudo option is passed through as false" do
        it "sets the value of sudo to 'false' if provided" do
          options.merge!(sudo: false)
          obj = subject.new(options)

          obj.send(:sudo).should be_false
        end
      end
    end
  end

  subject { described_class.new(options) }

  describe "MixinMethods" do

    describe "#templates_path" do
      it "returns a pathname" do
        subject.templates_path.should be_a(Pathname)
      end
    end

    describe "#first_boot" do
      it "returns a string" do
        subject.first_boot.should be_a(String)
      end
    end

    describe "#encrypted_data_bag_secret" do
      it "returns a string" do
        subject.encrypted_data_bag_secret.should be_a(String)
      end
    end

    describe "#validation_key" do
      it "returns a string" do
        subject.validation_key.should be_a(String)
      end
    end

    describe "template" do
      it "returns a string" do
        subject.template.should be_a(Erubis::Eruby)
      end
    end
  end

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

  describe "#default_template" do
    it "returns a string" do
      subject.default_template.should be_a(String)
    end
  end

  describe "#bootstrap_directory" do
    it "returns a string" do
      subject.bootstrap_directory.should be_a(String)
    end
  end
end
