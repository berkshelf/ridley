require 'spec_helper'

describe Ridley::UnixTemplateBinding do

  let(:options) do
    {
      server_url: "https://api.opscode.com/organizations/vialstudios",
      validator_client: "chef-validator",
      validator_path: fixtures_path.join("reset.pem").to_s,
      encrypted_data_bag_secret_path: fixtures_path.join("reset.pem").to_s
    }
  end
  
  subject { Ridley::UnixTemplateBinding.new(options) }

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
end
