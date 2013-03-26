require 'spec_helper'

describe Ridley::Connector::WinRM::Worker do
  let(:host) { 'reset.riotgames.com' }  
  
  let(:options) do
    {
      winrm_port: 1234
    }
  end

  subject { Ridley::Connector::WinRM::Worker.new(host, options) }

  describe "#winrm_port" do
    it "can be overridden if options contains :winrm_port" do
      subject.winrm_port.should eq(1234)
    end

    it "defaults to Ridley::Connector::DEFAULT_WINRM_PORT when not overridden" do
      options.delete(:winrm_port)
      subject.winrm_port.should eq(Ridley::Connector::DEFAULT_WINRM_PORT)
    end
  end

  describe "#winrm" do
    it "returns a WinRM::WinRMWebService" do
      subject.winrm.should be_a(WinRM::WinRMWebService)
    end
  end
end