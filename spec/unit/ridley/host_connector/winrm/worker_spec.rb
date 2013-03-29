require 'spec_helper'

describe Ridley::HostConnector::WinRM::Worker do
  let(:host) { 'reset.riotgames.com' }  
  
  let(:options) do
    {
      winrm: {
        port: 1234
      }
    }
  end

  subject { Ridley::HostConnector::WinRM::Worker.new(host, options) }

  describe "#winrm_port" do
    it "can be overridden if options contains :winrm_port" do
      subject.winrm_port.should eq(1234)
    end

    it "defaults to Ridley::HostConnector::DEFAULT_WINRM_PORT when not overridden" do
      options.delete(:winrm)
      subject.winrm_port.should eq(Ridley::HostConnector::DEFAULT_WINRM_PORT)
    end
  end

  describe "#winrm" do
    it "returns a WinRM::WinRMWebService" do
      subject.winrm.should be_a(WinRM::WinRMWebService)
    end
  end

  describe "#_upload_command" do
    let(:command) { "echo %TEMP%" }
    context "when a command is less than 2047 characters" do
      it "returns the command" do
        subject._upload_command(command).should eq(command)
      end
    end
  end
end
