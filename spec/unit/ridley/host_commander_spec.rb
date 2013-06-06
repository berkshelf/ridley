require 'spec_helper'

describe Ridley::HostCommander do
  subject { described_class.new }

  describe "#run" do
    let(:host) { "reset.riotgames.com" }
    let(:command) { "ls" }
    let(:options) do
      { ssh: { port: 22 }, winrm: { port: 5985 } }
    end

    context "when communicating to a unix node" do
      before do
        subject.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(false)
        subject.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(true)
      end

      it "sends a #run message to the ssh host connector" do
        subject.send(:ssh).should_receive(:run).with(host, command, options)

        subject.run(host, command, options)
      end
    end

    context "when communicating to a windows node" do
      before do
        subject.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(true)
        subject.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(false)
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
        subject.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(false)
        subject.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(true)
      end

      it "sends a #bootstrap message to the ssh host connector" do
        subject.send(:ssh).should_receive(:bootstrap).with(host, options)

        subject.bootstrap(host, options)
      end
    end

    context "when communicating to a windows node" do
      before do
        subject.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(true)
        subject.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(false)
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
        subject.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(false)
        subject.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(true)
      end

      it "sends a #chef_client message to the ssh host connector" do
        subject.send(:ssh).should_receive(:chef_client).with(host, options)

        subject.chef_client(host, options)
      end
    end

    context "when communicating to a windows node" do
      before do
        subject.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(true)
        subject.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(false)
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
        subject.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(false)
        subject.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(true)
      end

      it "sends a #put_secret message to the ssh host connector" do
        subject.send(:ssh).should_receive(:put_secret).with(host, secret, options)

        subject.put_secret(host, secret, options)
      end
    end

    context "when communicating to a windows node" do
      before do
        subject.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(true)
        subject.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(false)
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
        subject.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(false)
        subject.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(true)
      end

      it "sends a #ruby_script message to the ssh host connector" do
        subject.send(:ssh).should_receive(:ruby_script).with(host, command_lines, options)

        subject.ruby_script(host, command_lines, options)
      end
    end

    context "when communicating to a windows node" do
      before do
        subject.stub(:connector_port_open?).with(host, options[:winrm][:port]).and_return(true)
        subject.stub(:connector_port_open?).with(host, options[:ssh][:port], anything).and_return(false)
      end

      it "sends a #ruby_script message to the ssh host connector" do
        subject.send(:winrm).should_receive(:ruby_script).with(host, command_lines, options)

        subject.ruby_script(host, command_lines, options)
      end
    end
  end
end
