require 'spec_helper'

describe Ridley::HostConnector::SSH::Worker do
  subject { ssh_worker }
  let(:ssh_worker) { described_class.new(host, options) }

  let(:host) { 'reset.riotgames.com' }
  let(:options) { {} }

  describe "#sudo" do
    subject { ssh_worker.sudo }

    it { should be_false }

    context "with sudo" do
      let(:options) { { ssh: { sudo: true } } }

      it { should be_true }
    end
  end

  describe "#chef_client" do
    subject(:chef_client) { ssh_worker.chef_client }

    it { should be_a(Array) }

    context "with sudo" do
      let(:options) { { ssh: { sudo: true } } }

      it "sends a run command with sudo" do
        ssh_worker.should_receive(:run).with("sudo chef-client")
        chef_client
      end
    end
  end

  describe "#put_secret" do
    subject(:put_secret) { ssh_worker.put_secret(secret) }
    let(:encrypted_data_bag_secret_path) { fixtures_path.join("encrypted_data_bag_secret").to_s }
    let(:secret) { File.read(encrypted_data_bag_secret_path).chomp }

    it "receives a run command with echo" do
      ssh_worker.should_receive(:run).with("echo '#{secret}' > /etc/chef/encrypted_data_bag_secret; chmod 0600 /etc/chef/encrypted_data_bag_secret")
      put_secret
    end
  end

  describe "#ruby_script" do
    subject(:ruby_script) { ssh_worker.ruby_script(command_lines) }
    let(:command_lines) { ["puts 'hello'", "puts 'there'"] }

    it "receives a ruby call with the command" do
      ssh_worker.should_receive(:run).with("#{described_class::EMBEDDED_RUBY_PATH} -e \"puts 'hello';puts 'there'\"")
      ruby_script
    end
  end
end
