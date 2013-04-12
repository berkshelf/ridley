require 'spec_helper'

describe Ridley::Bootstrapper do
  let(:nodes) do
    [
      "33.33.33.10"
    ]
  end

  let(:options) do
    {
      ssh_user: "vagrant",
      ssh_password: "vagrant",
      server_url: "https://api.opscode.com/organizations/vialstudios",
      validator_client: "vialstudios-validator",
      validator_path: fixtures_path.join("reset.pem").to_s,
      encrypted_data_bag_secret_path: fixtures_path.join("reset.pem").to_s
    }
  end

  before(:each) { Ridley::HostConnector.stub(:best_connector_for).and_return(Ridley::HostConnector::SSH) }

  describe "ClassMethods" do
    subject { Ridley::Bootstrapper }

    describe "::new" do
      context "given a single string for nodes" do
        before(:each) do
          @obj = subject.new("33.33.33.10", options)
        end

        it "has one node" do
          @obj.hosts.should have(1).item
        end

        it "has one context" do
          @obj.contexts.should have(1).item
        end
      end

      context "given an an array of strings nodes" do
        before(:each) do
          @obj = subject.new(["33.33.33.10", "33.33.33.11"], options)
        end

        it "has a host for each item given" do
          @obj.hosts.should have(2).items
        end

        it "has a context for each item given" do
          @obj.contexts.should have(2).items
        end
      end
    end
  end

  subject { Ridley::Bootstrapper.new(nodes, options) }

  describe "#hosts" do
    it "returns an array of strings" do
      subject.hosts.should be_a(Array)
      subject.hosts.should each be_a(String)
    end
  end

  describe "#contexts" do
    before do
      Ridley::Bootstrapper::Context.stub(:create).and_return(double)
    end

    it "creates a new context for each host" do
      Ridley::Bootstrapper::Context.should_receive(:create).exactly(nodes.length).times
      subject.contexts
    end

    it "contains a item for each host" do
      subject.contexts.should have(nodes.length).items
    end

    context "when a host is unreachable" do
      before do
        Ridley::Bootstrapper::Context.stub(:create).and_raise(Ridley::Errors::HostConnectionError)
      end

      it "raises a HostConnectionError" do
        expect {
          subject.contexts
        }.to raise_error(Ridley::Errors::HostConnectionError)
      end
    end
  end

  describe "#run" do
    pending
  end
end
