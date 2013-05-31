require 'spec_helper'

describe Ridley::HostCommander do
  describe "::new" do
    let(:host) { "192.168.1.1" }
    let(:options) do
      {
        ssh: {
          user: "reset",
          password: "lol"
        },
        winrm: {
          user: "Administrator",
          password: "secret"
        }
      }
    end

    subject { described_class.new(host, options) }

    context "when the best connector is SSH" do
      before do
        described_class.stub(:best_connector_for).and_yield(Ridley::HostConnector::SSH)
      end

      it { should be_a(Ridley::HostConnector::SSH::Worker) }
      its(:user) { should eq("reset") }
    end

    context "when the best connector is WinRM" do
      before do
        described_class.stub(:best_connector_for).and_yield(Ridley::HostConnector::WinRM)
      end

      it { should be_a(Ridley::HostConnector::WinRM::Worker) }
      its(:user) { should eq("Administrator") }
      its(:password) { should eq("secret") }
    end
  end

  describe "::connector_port_open?" do
    let(:host) { "127.0.0.1" }
    let(:port) { 22 }
    let(:socket) { double(:new => true, :close => nil) }

    context "when a port is open" do
      before do
        TCPSocket.stub(:new).and_return(socket)
      end

      it "returns true" do
        subject.connector_port_open?(host, port).should eql(true)
      end

      it "closes the opened socket" do
        socket.should_receive(:close)
        subject.connector_port_open?(host, port)
      end
    end

    context "when a port is closed" do
      before do
        TCPSocket.stub(:new).and_raise(Errno::ECONNREFUSED)
      end

      it "returns false" do
        subject.connector_port_open?(host, port).should eq(false)
      end
    end

    context "when host is unreachable" do
      before do
        TCPSocket.stub(:new).and_raise(SocketError)
      end

      it "returns false" do
        subject.connector_port_open?(host, port).should eql(false)
      end
    end
  end

  describe "::connector_for" do
    let(:host) {"127.0.0.1"}

    context "when an SSH port is open" do
      it "returns Ridley::HostConnector::SSH" do
        subject.stub(:connector_port_open?).and_return(false, true)
        expect(subject.connector_for(host)).to eq(Ridley::HostConnector::SSH)
      end
    end

    context "when an SSH port isnt open and a WinRM port is open" do
      it "retrns Ridley::HostConnector::WinRM" do
        subject.stub(:connector_port_open?).and_return(true, false)
        expect(subject.connector_for(host)).to eq(Ridley::HostConnector::WinRM)
      end
    end

    context "when no useable ports are open" do
      it "raises an exception" do
        subject.stub(:connector_port_open?).and_return(false, false)
        expect {
          subject.connector_for(host)
        }.to raise_error(Ridley::Errors::HostConnectionError)
      end
    end

    context "when a block is provided" do
      it "yields the best HostConnector to the block" do
        subject.stub(:connector_port_open?).and_return(false, true)
        subject.connector_for(host) do |yielded|
          expect(yielded).to eq(Ridley::HostConnector::SSH)
        end
      end
    end
  end
end
