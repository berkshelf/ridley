require 'spec_helper'

describe Ridley::HostConnector::WinRM::CommandUploader do
  let(:winrm_stub) {
    double('WinRM',
      run_cmd: run_cmd_data,
      powershell: nil
    )
  }

  describe "::cleanup" do
    subject { cleanup }

    let(:cleanup) { described_class.cleanup(winrm_stub) }

    it "cleans up the windows temp dir" do
      winrm_stub.should_receive(:run_cmd).with("del %TEMP%\\winrm-upload* /F /Q")
      cleanup
    end
  end

  subject { command_uploader }

  let(:command_uploader) { described_class.new(command_string, winrm_stub) }
  let(:command_string) { "a" * 2048 }
  let(:run_cmd_data) { { data: [{ stdout: "abc123" }] } }

  its(:command_string) { should eq(command_string) }
  its(:winrm) { should eq(winrm_stub) }

  describe "#upload" do
    let(:upload) { command_uploader.upload }

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
    let(:command_file_name) { "my_command.bat" }

    before do
      command_uploader.stub command_file_name: command_file_name
    end

    it { should eq("cmd.exe /C #{command_file_name}") }
  end
end