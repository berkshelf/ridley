require 'spec_helper'

describe Ridley::HostCommander do
  describe "ClassMethods" do
    subject { described_class }

    describe "::connector_port_open?" do
      let(:host) { "127.0.0.1" }
      let(:port) { 22 }
      let(:socket) { double(close: nil) }

      before { TCPSocket.stub(:new).and_return(socket) }

      subject(:result) { described_class.connector_port_open?(host, port) }

      context "when a port is open" do
        it { should be_true }

        it "closes the opened socket" do
          socket.should_receive(:close)
          result
        end
      end

      context "when a port is closed" do
        before { TCPSocket.stub(:new).and_raise(Errno::ECONNREFUSED) }

        it { should be_false }
      end

      context "when host is unreachable" do
        before { TCPSocket.stub(:new).and_raise(SocketError) }

        it { should be_false }
      end
    end
  end

  subject { described_class.new }

  describe "#run" do
    let(:host) { "reset.riotgames.com" }
    let(:command) { "ls" }
    let(:options) do
      { ssh: { port: 22 }, winrm: { port: 5985 } }
    end

    context "when communicating to a unix node" do
      before do
        described_class.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(false)
        described_class.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(true)
      end

      it "sends a #run message to the ssh host connector" do
        subject.send(:ssh).should_receive(:run).with(host, command, options)

        subject.run(host, command, options)
      end
    end

    context "when communicating to a windows node" do
      before do
        described_class.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(true)
        described_class.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(false)
      end

      it "sends a #run message to the ssh host connector" do
        subject.send(:winrm).should_receive(:run).with(host, command, options)

        subject.run(host, command, options)
      end
    end
  end

  describe "#bootstrap" do
    let(:host) { "reset.riotgames.com" }
    let(:options) do
      { ssh: { port: 22 }, winrm: { port: 5985 } }
    end

    context "when communicating to a unix node" do
      before do
        described_class.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(false)
        described_class.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(true)
      end

      it "sends a #bootstrap message to the ssh host connector" do
        subject.send(:ssh).should_receive(:bootstrap).with(host, options)

        subject.bootstrap(host, options)
      end
    end

    context "when communicating to a windows node" do
      before do
        described_class.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(true)
        described_class.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(false)
      end

      it "sends a #bootstrap message to the ssh host connector" do
        subject.send(:winrm).should_receive(:bootstrap).with(host, options)

        subject.bootstrap(host, options)
      end
    end
  end

  describe "#chef_client" do
    let(:host) { "reset.riotgames.com" }
    let(:options) do
      { ssh: { port: 22 }, winrm: { port: 5985 } }
    end

    context "when communicating to a unix node" do
      before do
        described_class.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(false)
        described_class.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(true)
      end

      it "sends a #chef_client message to the ssh host connector" do
        subject.send(:ssh).should_receive(:chef_client).with(host, options)

        subject.chef_client(host, options)
      end
    end

    context "when communicating to a windows node" do
      before do
        described_class.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(true)
        described_class.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(false)
      end

      it "sends a #chef_client message to the ssh host connector" do
        subject.send(:winrm).should_receive(:chef_client).with(host, options)

        subject.chef_client(host, options)
      end
    end
  end

  describe "#put_secret" do
    let(:host) { "reset.riotgames.com" }
    let(:secret) { "something_secret" }
    let(:options) do
      { ssh: { port: 22 }, winrm: { port: 5985 } }
    end

    context "when communicating to a unix node" do
      before do
        described_class.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(false)
        described_class.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(true)
      end

      it "sends a #put_secret message to the ssh host connector" do
        subject.send(:ssh).should_receive(:put_secret).with(host, secret, options)

        subject.put_secret(host, secret, options)
      end
    end

    context "when communicating to a windows node" do
      before do
        described_class.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(true)
        described_class.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(false)
      end

      it "sends a #put_secret message to the ssh host connector" do
        subject.send(:winrm).should_receive(:put_secret).with(host, secret, options)

        subject.put_secret(host, secret, options)
      end
    end
  end

  describe "#ruby_script" do
    let(:host) { "reset.riotgames.com" }
    let(:command_lines) { ["line one"] }
    let(:options) do
      { ssh: { port: 22 }, winrm: { port: 5985 } }
    end

    context "when communicating to a unix node" do
      before do
        described_class.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(false)
        described_class.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(true)
      end

      it "sends a #ruby_script message to the ssh host connector" do
        subject.send(:ssh).should_receive(:ruby_script).with(host, command_lines, options)

        subject.ruby_script(host, command_lines, options)
      end
    end

    context "when communicating to a windows node" do
      before do
        described_class.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(true)
        described_class.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(false)
      end

      it "sends a #ruby_script message to the ssh host connector" do
        subject.send(:winrm).should_receive(:ruby_script).with(host, command_lines, options)

        subject.ruby_script(host, command_lines, options)
      end
    end
  end
end
