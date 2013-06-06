require 'spec_helper'

describe Ridley::HostConnector::WinRM do
  subject { connector }
  let(:connector) { described_class.new }
  let(:host) { 'reset.riotgames.com' }
  let(:options) do
    {
      server_url: double('server_url'),
      validator_path: fixtures_path.join('reset.pem'),
      validator_client: double('validator_client'),
      encrypted_data_bag_secret: 'encrypted_data_bag_secret',
      winrm: Hash.new,
      chef_version: double('chef_version')
    }
  end

  before { described_class::CommandUploader.stub(:new).and_return(double('command_uploader')) }

  describe "#get_command" do
    subject(:get_command) { connector.get_command(command, command_uploader_stub) }

    let(:command) { "echo %TEMP%" }
    let(:command_uploader_stub) { double('CommandUploader') }

    it { should eq(command) }

    context "when a command is more than 2047 characters" do
      let(:command) { "a" * 2048 }

      it "uploads and returns a command" do
        described_class::CommandUploader.stub(new: command_uploader_stub)

        command_uploader_stub.should_receive :upload
        command_uploader_stub.stub command: "my command"
        command_uploader_stub.stub(:cleanup)

        get_command.should eq("my command")
      end
    end
  end

  describe "#run" do
    subject(:result) { connector.run(host, command, options) }
    let(:command) { "dir" }
    let(:command_uploader_stub) { double('CommandUploader', cleanup: true) }
    let(:stdout) { "stdout" }
    let(:stderr) { nil }
    let(:winrm_stub) { double }

    before do
      described_class::CommandUploader.stub(:new).and_return(command_uploader_stub)
      connector.stub(:winrm).and_return(winrm_stub)
      winrm_stub.stub(:run_cmd).and_yield(stdout, stderr).and_return(exitcode: 0)
    end

    context "when the exit_code is 0" do
      it "returns a non-error HostConnector::Response" do
        expect(result).to be_a(Ridley::HostConnector::Response)
        expect(result).to_not be_error
      end

      it "sets the response's stdout message" do
        expect(result.stdout).to eq("stdout")
      end
    end

    context "when the exit_code is not 0" do
      let(:stderr) { "stderr" }

      before do
        winrm_stub.stub(:run_cmd).and_yield(stdout, stderr).and_return(exitcode: 1)
      end

      it "returns an error HostConnector::Response with an error" do
        expect(result).to be_a(Ridley::HostConnector::Response)
        expect(result).to be_error
      end

      it "sets the response's stderr message" do
        expect(result.stderr).to eq("stderr")
      end
    end

    context "when a WinRM::WinRMHTTPTransportError error is raised" do
      let(:stderr) { "error" }
      before { winrm_stub.stub(:run_cmd).and_yield(stdout, stderr).and_raise(::WinRM::WinRMHTTPTransportError) }

      it "returns an error HostConnector::Response with an error" do
        expect(result).to be_a(Ridley::HostConnector::Response)
        expect(result).to be_error
      end

      it "sets the response's stderr message to the exception's message" do
        expect(result.stderr).to eql("WinRM::WinRMHTTPTransportError")
      end
    end
  end

  describe "#bootstrap" do
    it "sends a #run message to self to bootstrap a node" do
      connector.should_receive(:run).with(host, anything, options)
      connector.bootstrap(host, options)
    end
  end

  describe "#chef_client" do
    subject(:chef_client) { connector.chef_client(host, options) }

    it "receives a command to run chef-client" do
      connector.should_receive(:run).with(host, "chef-client", options)

      chef_client
    end
  end

  describe "#put_secret" do
    subject(:put_secret) { connector.put_secret(host, secret, options) }
    let(:encrypted_data_bag_secret_path) { fixtures_path.join("encrypted_data_bag_secret").to_s }
    let(:secret) { File.read(encrypted_data_bag_secret_path).chomp }

    it "receives a command to copy the secret" do
      connector.should_receive(:run).with(host,
        "echo #{secret} > C:\\chef\\encrypted_data_bag_secret",
        options
      )

      put_secret
    end
  end

  describe "#ruby_script" do
    subject(:ruby_script) { connector.ruby_script(host, command_lines, options) }
    let(:command_lines) { ["puts 'hello'", "puts 'there'"] }

    it "receives a ruby call with the command" do
      connector.should_receive(:run).with(host,
        "#{described_class::EMBEDDED_RUBY_PATH} -e \"puts 'hello';puts 'there'\"",
        options
      )

      ruby_script
    end
  end
end
