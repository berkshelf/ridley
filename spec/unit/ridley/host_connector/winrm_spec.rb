require 'spec_helper'

describe Ridley::HostConnector::WinRM do
  let(:connection) { double('conn', ssh: { user: "vagrant", password: "vagrant" }) }

  let(:node_one) do
    Ridley::NodeResource.new(connection, automatic: { cloud: { public_hostname: "33.33.33.10" } })
  end

  let(:node_two) do
    Ridley::NodeResource.new(connection, automatic: { cloud: { public_hostname: "33.33.33.11" } })
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

  describe "#chef_client" do
    it "receives a command to run 'chef-client'" do
      subject.should_receive(:run).with("chef-client")
      subject.chef_client
    end
  end

  describe "#put_secret" do
    let(:encrypted_data_bag_secret_path) { fixtures_path.join("encrypted_data_bag_secret").to_s }

    it "receives a command to copy the secret" do
      secret  = File.read(encrypted_data_bag_secret_path).chomp
      subject.should_receive(:run).with("echo #{secret} > C:\\chef\\encrypted_data_bag_secret")
      subject.put_secret(encrypted_data_bag_secret_path)
    end
  end

  describe "#ruby_script" do
    let(:command_lines) { ["puts 'hello'", "puts 'there'"] }

    it "receives a ruby call with the command" do
      subject.should_receive(:run).with("#{described_class::EMBEDDED_RUBY_PATH} -e \"puts 'hello';puts 'there'\"")
      subject.ruby_script(command_lines)
    end
  end
end
