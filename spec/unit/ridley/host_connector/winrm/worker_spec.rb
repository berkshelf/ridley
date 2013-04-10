require 'spec_helper'

describe Ridley::HostConnector::WinRM::Worker do
  subject { winrm_worker }
  let(:winrm_worker) { described_class.new(host, options) }
  let(:host) { 'reset.riotgames.com' }  
  let(:options) { {} }

  describe "#winrm_port" do
    subject(:winrm_port) { winrm_worker.winrm_port }

    it { should eq(Ridley::HostConnector::DEFAULT_WINRM_PORT) }

    context "when overridden" do
      let(:options) { { winrm: { port: 1234 } } }

      it { should eq(1234) }
    end
  end

  describe "#winrm" do
    subject { winrm_worker.winrm }

    it { should be_a(WinRM::WinRMWebService) }
  end

  describe "#get_command" do
    subject(:get_command) { winrm_worker.get_command(command) }

    let(:command) { "echo %TEMP%" }

    it { should eq(command) }
    
    context "when a command is more than 2047 characters" do
      let(:command) { "a" * 2048 }

      it "uploads and returns a command" do
        command_uploader_stub = double('CommandUploader')
        Ridley::HostConnector::WinRM::CommandUploader.stub new: command_uploader_stub

        command_uploader_stub.should_receive :upload
        command_uploader_stub.stub command: "my command"

        get_command.should eq("my command")
      end
    end
  end

  describe "#chef_client" do
    subject(:chef_client) { winrm_worker.chef_client }

    it "receives a command to run chef-client" do
      winrm_worker.should_receive(:run).with("chef-client")

      chef_client
    end
  end

  describe "#put_secret" do
    subject(:put_secret) { winrm_worker.put_secret(encrypted_data_bag_secret_path) }

    let(:encrypted_data_bag_secret_path) { fixtures_path.join("encrypted_data_bag_secret").to_s }
    let(:secret) { File.read(encrypted_data_bag_secret_path).chomp }

    it "receives a command to copy the secret" do
      winrm_worker.should_receive(:run).with("echo #{secret} > C:\\chef\\encrypted_data_bag_secret")

      put_secret
    end
  end

  describe "#ruby_script" do
    subject(:ruby_script) { winrm_worker.ruby_script(command_lines) }
    let(:command_lines) { ["puts 'hello'", "puts 'there'"] }

    it "receives a ruby call with the command" do
      winrm_worker.should_receive(:run).with("#{described_class::EMBEDDED_RUBY_PATH} -e \"puts 'hello';puts 'there'\"")

      ruby_script
    end
  end
end
