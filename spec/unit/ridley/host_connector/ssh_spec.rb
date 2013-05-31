require 'spec_helper'

describe Ridley::HostConnector::SSH do
  subject { connector }
  let(:connector) { described_class.new }

  let(:host) { 'reset.riotgames.com' }
  let(:options) { Hash.new }

  describe "#bootstrap" do
    pending
  end

  describe "#chef_client" do
    subject(:chef_client) { connector.chef_client(host, options) }

    it { should be_a(Array) }

    it "sends a run command to execute chef-client" do
      connector.should_receive(:run).with(host, "chef-client", options)
      chef_client
    end
  end

  describe "#put_secret" do
    subject(:put_secret) { connector.put_secret(host, secret, options) }
    let(:encrypted_data_bag_secret_path) { fixtures_path.join("encrypted_data_bag_secret").to_s }
    let(:secret) { File.read(encrypted_data_bag_secret_path).chomp }

    it "receives a run command with echo" do
      connector.should_receive(:run).with(host,
        "echo '#{secret}' > /etc/chef/encrypted_data_bag_secret; chmod 0600 /etc/chef/encrypted_data_bag_secret",
        options
      )
      put_secret
    end
  end

  describe "#ruby_script" do
    subject(:ruby_script) { connector.ruby_script(host, command_lines, options) }
    let(:command_lines) { ["puts 'hello'", "puts 'there'"] }

    it "receives a ruby call with the command" do
      connector.should_receive(:run).with(host,
        "#{described_class::EMBEDDED_RUBY_PATH} -e \"puts 'hello';puts 'there'\"",
        options
      )
      ruby_script
    end
  end
end
