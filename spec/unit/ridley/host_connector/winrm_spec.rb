require 'spec_helper'

describe Ridley::HostConnector::WinRM do
  let(:connection) { double('conn', ssh: { user: "vagrant", password: "vagrant" }) }

  let(:node_one) do
    Ridley::NodeResource.new(connection, automatic: { cloud: { public_hostname: "33.33.33.10" } })
  end

  let(:node_two) do
    Ridley::NodeResource.new(connection, automatic: { cloud: { public_hostname: "33.33.33.11" } })
  end
  let(:command_uploader) { double('command_uploader', cleanup: nil) }

  before do
    Ridley::HostConnector::WinRM::CommandUploader.stub(:new).and_return(command_uploader)
  end

  describe "ClassMethods" do
    subject { Ridley::HostConnector::WinRM }
    
    describe "::start" do
      let(:options) do
        {
          user: "Administrator",
          password: "password1"
        }
      end

      it "evaluates within the context of a new WinRM and returns the last item in the block" do
        result = subject.start([node_one, node_two], options) do |winrm|
          winrm.run("dir")
        end
        result.should be_a(Ridley::HostConnector::ResponseSet)
      end

      it "raises a LocalJumpError if a block is not provided" do
        expect {
          subject.start([node_one, node_two], options)
        }.to raise_error(LocalJumpError)
      end
    end
  end

  subject { Ridley::HostConnector::WinRM.new([node_one, node_two], user: 'Administrator', password: 'password1') }

  describe "#run" do
    it "returns a ResponseSet" do
      subject.run("dir").should be_a(Ridley::HostConnector::ResponseSet)
    end
  end
end
