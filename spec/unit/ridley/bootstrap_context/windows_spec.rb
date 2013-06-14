require 'spec_helper'

describe Ridley::BootstrapContext::Windows do
  let(:options) do
    {
      server_url: "https://api.opscode.com/organizations/vialstudios",
      validator_client: "chef-validator",
      validator_path: fixtures_path.join("reset.pem").to_s,
      encrypted_data_bag_secret: File.read(fixtures_path.join("reset.pem")),
      chef_version: "11.4.0"
    }
  end

  describe "ClassMethods" do
    subject { described_class }

    describe "::new" do
      context "when a chef_version is passed through" do
        it "sets the chef_version attribute to the same value" do
          subject.new(options).chef_version.should eq("11.4.0")
        end
      end

      context "when the chef_version is not passed through" do
        it "sets the chef_version to 'latest'" do
          options.delete(:chef_version)
          subject.new(options).chef_version.should eq("latest")
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

  describe "#env_path" do
    it "returns a string" do
      expect(subject.env_path).to be_a(String)
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

  describe "#escape_and_echo" do
    let(:output) { "foo()" }

    it "adds 'echo.' to the beginning of each line and escapes special batch characters" do
      subject.escape_and_echo(output).should eq("echo.foo^(^)")
    end
  end

  describe "#windows_wget_powershell" do
    it "returns a string" do
      subject.windows_wget_powershell.should be_a(String)
    end
  end
end
