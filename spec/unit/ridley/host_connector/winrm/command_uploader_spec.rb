require 'spec_helper'

describe Ridley::HostConnector::WinRM::CommandUploader do
  let(:winrm_stub) {
    double('WinRM',
      run_cmd: run_cmd_data,
      powershell: nil
    )
  }

  subject { command_uploader }

  let(:command_uploader) { described_class.new(winrm_stub) }
  let(:command_string) { "a" * 2048 }
  let(:run_cmd_data) { { data: [{ stdout: "abc123" }] } }
  let(:command_file_name) { "my_command.bat" }

  its(:winrm) { should eq(winrm_stub) }

  before do
    command_uploader.stub(:get_file_path).and_return("")
  end

  describe "#upload" do
    let(:upload) { command_uploader.upload(command_string) }

    it "calls winrm to upload and convert the command" do
      winrm_stub.should_receive(:run_cmd).and_return(
        run_cmd_data,
        nil,
        run_cmd_data
      )
      winrm_stub.should_receive(:powershell)

      upload
    end
  end

  describe "#command" do
    subject { command }
    let(:command) { command_uploader.command }

    before do
      command_uploader.stub command_file_name: command_file_name
    end

    it { should eq("cmd.exe /C #{command_file_name}") }
  end

  describe "#cleanup" do
    subject { cleanup }

    let(:cleanup) { command_uploader.cleanup }
    let(:base64_file_name) { "my_base64_file" }

    before do
      command_uploader.stub command_file_name: command_file_name
      command_uploader.stub base64_file_name: base64_file_name
    end

    it "cleans up the windows temp dir" do
      winrm_stub.should_receive(:run_cmd).with("del #{base64_file_name} /F /Q")
      winrm_stub.should_receive(:run_cmd).with("del #{command_file_name} /F /Q")
      cleanup
    end
  end
end
