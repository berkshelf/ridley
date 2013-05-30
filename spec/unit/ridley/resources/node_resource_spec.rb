require 'spec_helper'

describe Ridley::NodeResource do
  let(:host) { "33.33.33.10" }
  let(:worker) { double('worker', alive?: true, terminate: nil) }
  let(:instance) do
    inst = described_class.new(double)
    inst.stub(connection: chef_zero_connection)
    inst
  end

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
    let(:put_secret) { instance.put_secret(host) }
    let(:response) { [ :ok, double('response', stdout: 'success_message') ] }
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
    let(:node_name) { "rspec-test" }
    let(:run_list) { [ "recipe[one]", "recipe[two]" ] }
    let(:attributes) { { deep: { two: "val" } } }

    subject(:result) { instance.merge_data(node_name, run_list: run_list, attributes: attributes) }

    context "when a node of the given name exists" do
      before do
        chef_node(node_name,
          run_list: [ "recipe[one]", "recipe[three]" ],
          normal: { deep: { one: "val" } }
        )
      end

      it "returns a Ridley::NodeObject" do
        expect(result).to be_a(Ridley::NodeObject)
      end

      it "has a union between the run list of the original node and the new run list" do
        expect(result.run_list).to eql(["recipe[one]","recipe[three]","recipe[two]"])
      end

      it "has a deep merge between the attributes of the original node and the new attributes" do
        expect(result.normal.to_hash).to eql(deep: { one: "val", two: "val" })
      end
    end

    context "when a node with the given name does not exist" do
      let(:node_name) { "does_not_exist" }

      it "raises a ResourceNotFound error" do
        expect { result }.to raise_error(Ridley::Errors::ResourceNotFound)
      end
    end
  end
end
