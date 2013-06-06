require 'spec_helper'

describe Ridley::HostConnector::Base do
  subject { Class.new(Ridley::HostConnector::Base).new }

  let(:host) { double('host') }
  let(:options) { Hash.new }

  describe "#run" do
    let(:command) { double('command') }

    it "raises a RuntimeError" do
      expect { subject.run(host, command, options) }.to raise_error(RuntimeError)
    end
  end

  describe "#bootstrap" do
    it "raises a RuntimeError" do
      expect { subject.bootstrap(host, options) }.to raise_error(RuntimeError)
    end
  end

  describe "#chef_client" do
    it "raises a RuntimeError" do
      expect { subject.chef_client(host, options) }.to raise_error(RuntimeError)
    end
  end

  describe "#put_secret" do
    let(:secret) { double('secret') }

    it "raises a RuntimeError" do
      expect { subject.put_secret(host, secret, options) }.to raise_error(RuntimeError)
    end
  end

  describe "#ruby_script" do
    let(:command_lines) { double('command-lines') }

    it "raises a RuntimeError" do
      expect { subject.ruby_script(host, command_lines, options) }.to raise_error(RuntimeError)
    end
  end

  describe "#uninstall_chef" do
    it "raises a RuntimeError" do
      expect { subject.uninstall_chef(host, options) }.to raise_error(RuntimeError)
    end
  end
end
