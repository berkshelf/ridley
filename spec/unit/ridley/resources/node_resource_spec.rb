require 'spec_helper'

describe Ridley::NodeResource do
  let(:host) { "33.33.33.10" }
  let(:worker) { double('worker', alive?: true, terminate: nil) }
  let(:options) do
    {
      server_url: "https://api.opscode.com/organizations/vialstudios",
      validator_path: "/some/path",
      validator_client: "chef-validator",
      encrypted_data_bag_secret: "hellokitty",
      ssh: {
        user: "reset",
        password: "lol"
      },
      winrm: {
        user: "Administrator",
        password: "secret"
      },
      chef_version: "11.4.0"
    }
  end
  let(:instance) { described_class.new(double, options) }

  describe "#bootstrap" do
    let(:hosts) { [ "192.168.1.2" ] }
    let(:options) do
      {
        validator_path: fixtures_path.join("reset.pem").to_s,
        encrypted_data_bag_secret: File.read(fixtures_path.join("reset.pem"))
      }
    end
    let(:bootstrapper) { double('bootstrapper', run: nil) }
    subject { instance }
    before { Ridley::Bootstrapper.should_receive(:new).with(hosts, anything).and_return(bootstrapper) }

    it "runs the Bootstrapper" do
      bootstrapper.should_receive(:run)

      subject.bootstrap("192.168.1.2", options)
    end
  end

  describe "#chef_run" do
    let(:chef_run) { instance.chef_run(host) }
    let(:response) { [:ok, double('response', stdout: 'success_message')] }
    subject { chef_run }

    before do
      Ridley::HostConnector.stub(:new).and_return(worker)
      worker.stub(:chef_client).and_return(response)
    end

    it { should eql(response) }

    context "when it executes unsuccessfully" do
      let(:response) { [ :error, double('response', stderr: 'failure_message') ] }

      it { should eql(response) }
    end

    it "terminates the worker" do
      worker.should_receive(:terminate)
      chef_run
    end
  end

  describe "#put_secret" do
    let(:put_secret) { instance.put_secret(host, secret_path)}
    let(:response) { [ :ok, double('response', stdout: 'success_message') ] }
    let(:secret_path) { fixtures_path.join("reset.pem").to_s }
    subject { put_secret }

    before do
      Ridley::HostConnector.stub(:new).and_return(worker)
      worker.stub(:put_secret).and_return(response)
    end

    it { should eql(response) }

    context "when it executes unsuccessfully" do
      let(:response) { [ :error, double('response', stderr: 'failure_message') ] }

      it { should eql(response) }
    end

    it "terminates the worker" do
      worker.should_receive(:terminate)
      put_secret
    end
  end

  describe "#ruby_script" do
    let(:ruby_script) { instance.ruby_script(host, command_lines) }
    let(:response) { [:ok, double('response', stdout: 'success_message')] }
    let(:command_lines) { ["puts 'hello'", "puts 'there'"] }
    subject { ruby_script }

    before do
      Ridley::HostConnector.stub(:new).and_return(worker)
      worker.stub(:ruby_script).and_return(response)
    end

    it { should eq(response) }

    context "when it executes unsuccessfully" do
      let(:response) { [:error, double('response', stderr: 'failure_message')] }

      it { should eq(response) }
    end

    it "terminates the worker" do
      worker.should_receive(:terminate)
      ruby_script
    end
  end

  describe "#execute_command" do
    let(:execute_command) { instance.execute_command(host, command) }
    let(:response) { [:ok, double('response', stdout: 'success_message')] }
    let(:command) { "echo 'hello world'" }
    subject { execute_command }

    before do
      Ridley::HostConnector.stub(:new).and_return(worker)
      worker.stub(:run).and_return(response)
    end

    it { should eq(response) }

    context "when it executes unsuccessfully" do
      let(:response) { [:error, double('response', stderr: 'failure_message')] }

      it { should eq(response) }
    end
  end

  describe "#merge_data" do
    subject { instance }

    it "finds the target node and sends it the merge_data message" do
      data = double('data')
      node = double('node')
      node.should_receive(:merge_data).with(data)
      subject.should_receive(:find).and_return(node)

      subject.merge_data(node, data)
    end
  end
end
