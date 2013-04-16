require 'spec_helper'

describe Ridley::HostConnector::SSH do
  let(:resource) { double('resource') }

  let(:node_one) do
    Ridley::NodeObject.new(resource, automatic: { cloud: { public_hostname: "33.33.33.10" } })
  end

  let(:node_two) do
    Ridley::NodeObject.new(resource, automatic: { cloud: { public_hostname: "33.33.33.11" } })
  end

  let(:options) do
    {
      user: "vagrant",
      password: "vagrant",
      timeout: 1
    }
  end

  describe "ClassMethods" do
    subject { described_class }

    describe "::start" do
      it "raises a LocalJumpError if a block is not provided" do
        expect {
          subject.start([node_one, node_two], options)
        }.to raise_error(LocalJumpError)
      end
    end
  end

  subject do
    Ridley::HostConnector::SSH.new([node_one, node_two], ssh: { user: "vagrant", password: "vagrant", timeout: 1 })
  end

  describe "#run" do
    let(:worker) { double('worker', terminate: nil) }
    let(:response) { Ridley::HostConnector::Response.new("host") }
    before { Ridley::HostConnector::SSH::Worker.stub(:new).and_return(worker) }

    before do
      worker.stub_chain(:future, :run).and_return(double(value: [:ok, response]))
    end

    it "returns an SSH::ResponseSet" do
      subject.run("ls").should be_a(Ridley::HostConnector::ResponseSet)
    end
  end
end
