require 'spec_helper'

describe Ridley::HostConnector::WinRM::Worker do
  subject { winrm_worker }
  let(:winrm_worker) { described_class.new(host, options) }
  let(:host) { 'reset.riotgames.com' }
  let(:options) { {} }

  before do
    Ridley::HostConnector::WinRM::CommandUploader.stub(:new).and_return(double('command_uploader'))
  end

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

    it "returns a WinRM::WinRMWebService" do
      expect(subject).to be_a(::WinRM::WinRMWebService)
    end
  end

  describe "#get_command" do
    subject(:get_command) { winrm_worker.get_command(command, command_uploader_stub) }

    let(:command) { "echo %TEMP%" }
    let(:command_uploader_stub) { double('CommandUploader') }

    it { should eq(command) }

    context "when a command is more than 2047 characters" do
      let(:command) { "a" * 2048 }

      it "uploads and returns a command" do
        Ridley::HostConnector::WinRM::CommandUploader.stub new: command_uploader_stub

        command_uploader_stub.should_receive :upload
        command_uploader_stub.stub command: "my command"
        command_uploader_stub.stub(:cleanup)

        get_command.should eq("my command")
      end
    end
  end

  describe "#run" do
    subject(:run) { winrm_worker.run(command) }
    let(:command) { "dir" }
    let(:command_uploader_stub) { double('CommandUploader') }
    let(:stdout) { "stdout" }
    let(:stderr) { nil }
    let(:winrm_stub) { double }

    before do
      Ridley::HostConnector::WinRM::CommandUploader.stub(:new).and_return(command_uploader_stub)
      winrm_worker.stub(:winrm).and_return(winrm_stub)
      winrm_stub.stub(:run_cmd).and_yield(stdout, stderr).and_return({exitcode: 0})
    end

    context "when the exit_code is 0" do
      it "returns an :ok with the response" do
        status, response = run
        expect(status).to eq(:ok)
        expect(response.stdout).to eq("stdout")
      end
    end

    context "when the exit_code is not 0" do
      let(:stderr) { "stderr" }

      before do
        winrm_stub.stub(:run_cmd).and_yield(stdout, stderr).and_return({exitcode: 1})
      end

      it "returns an :error with the response" do
        status, response = run
        expect(status).to eq(:error)
        expect(response.stderr).to eq("stderr")
      end
    end

    context "when an error is raised" do
      let(:stderr) { "error" }

      before do
        winrm_stub.stub(:run_cmd).and_yield(stdout, stderr).and_raise("error")
      end

      it "returns an :error with the response" do
        status, response = run
        expect(status).to eq(:error)
        expect(response.stderr).to eq("error")
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
    subject(:put_secret) { winrm_worker.put_secret(secret) }
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
