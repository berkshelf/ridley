require 'spec_helper'

describe Ridley::WindowsTemplateBinding do
  let(:options) do
    {
      server_url: "https://api.opscode.com/organizations/vialstudios",
      validator_client: "chef-validator",
      validator_path: fixtures_path.join("reset.pem").to_s,
      encrypted_data_bag_secret_path: fixtures_path.join("reset.pem").to_s
    }
  end
  
  describe "ClassMethods" do
    subject { described_class }
    
    describe "::new" do
    end
  end

  subject { Ridley::WindowsTemplateBinding.new(options) }

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

  describe "#win_wget" do
    it "returns a string" do
      subject.win_wget.should be_a(String)
    end
  end

  describe "#win_wget_ps" do
    it "returns a string" do
      subject.win_wget_ps.should be_a(String)
    end
  end

end