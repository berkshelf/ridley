require 'spec_helper'

describe Ridley::NodeResource do
  it_behaves_like "a Ridley Resource", Ridley::NodeResource

  let(:connection) do
    double('conn',
      server_url: "https://api.opscode.com/organizations/vialstudios",
      validator_client: "chef-validator",
      ssh: {
        user: "reset",
        password: "lol"
      },
      winrm: {
        user: "Administrator",
        password: "secret"
      }
    )
  end

  describe "ClassMethods" do
    subject { Ridley::NodeResource }

    let(:worker) { double('worker', alive?: true, terminate: nil) }

    describe "::bootstrap" do
      let(:boot_options) do
        {
          validator_path: fixtures_path.join("reset.pem").to_s,
          encrypted_data_bag_secret_path: fixtures_path.join("reset.pem").to_s
        }
      end

      it "bootstraps a single node" do
        pending
        subject.bootstrap(connection, "33.33.33.10", boot_options)
      end

      it "bootstraps multiple nodes" do
        pending
        subject.bootstrap(connection, "33.33.33.10", "33.33.33.11", boot_options)
      end
    end

    describe "::chef_run" do
      subject { chef_run }
      let(:chef_run) { described_class.chef_run(connection, host) }
      let(:response) { [:ok, double('response', stdout: 'success_message')] }
      let(:host) { "33.33.33.10" }

      before do
        Ridley::NodeResource.stub(:configured_worker_for).and_return(worker)
        worker.stub(:chef_client).and_return(response)
      end

      context "when it executes successfully" do
        it "returns a successful response" do
          chef_run.stdout.should eq('success_message')
        end
      end

      context "when it executes unsuccessfully" do
        let(:response) { [:error, double('response', stderr: 'failure_message')] }

        it "raises a RemoteCommandError" do
          expect {
            chef_run
            }.to raise_error(Ridley::Errors::RemoteCommandError)
        end
      end

      it "terminates the worker" do
        worker.should_receive(:terminate)
        chef_run
      end
    end

    describe "::put_secret" do
      subject { put_secret }
      let(:put_secret) { described_class.put_secret(connection, host, secret_path)}
      let(:response) { [:ok, double('response', stdout: 'success_message')] }
      let(:host) { "33.33.33.10" }
      let(:secret_path) { fixtures_path.join("reset.pem").to_s }

      before do
        Ridley::NodeResource.stub(:configured_worker_for).and_return(worker)
        worker.stub(:put_secret).and_return(response)
      end

      context "when it executes successfully" do
        it "returns a successful response" do
          put_secret.stdout.should eq('success_message')
        end
      end

      context "when it executes unsuccessfully" do
        let(:response) { [:error, double('response', stderr: 'failure_message')] }

        it "returns nil" do
          put_secret.should be_nil
        end
      end

      it "terminates the worker" do
        worker.should_receive(:terminate)
        put_secret
      end
    end

    describe "::ruby_script" do
      subject { ruby_script }
      let(:ruby_script) { described_class.ruby_script(connection, host, command_lines) }
      let(:response) { [:ok, double('response', stdout: 'success_message')] }
      let(:host) { "33.33.33.10" }
      let(:command_lines) { ["puts 'hello'", "puts 'there'"] }

      before do
        Ridley::NodeResource.stub(:configured_worker_for).and_return(worker)
        worker.stub(:ruby_script).and_return(response)
      end

      context "when it executes successfully" do
        it "returns a successful response" do
          ruby_script.should eq('success_message')
        end
      end

      context "when it executes unsuccessfully" do
        let(:response) { [:error, double('response', stderr: 'failure_message')] }

        it "raises a RemoteScriptError" do
          expect {
            ruby_script
            }.to raise_error(Ridley::Errors::RemoteScriptError)
        end
      end

      context "when it executes with an unknown error" do
        let(:response) { [:unknown, double('response', stderr: 'failure_message')] }

        it "raises an ArgumentError" do
          expect {
            ruby_script
          }.to raise_error(ArgumentError)
        end
      end

      it "terminates the worker" do
        worker.should_receive(:terminate)
        ruby_script
      end
    end

    describe "::configured_worker_for" do
      subject { configured_worker_for }

      let(:configured_worker_for) { described_class.send(:configured_worker_for, connection, host) }
      let(:host) { "33.33.33.10" }

      context "when the best connector is SSH" do
        before do
          Ridley::HostConnector.stub(:best_connector_for).and_yield(Ridley::HostConnector::SSH)
        end

        it "returns an SSH worker instance" do
          configured_worker_for.should be_a(Ridley::HostConnector::SSH::Worker)
        end

        its(:user) { should eq("reset") }
      end

      context "when the best connector is WinRM" do
        before do
          Ridley::HostConnector.stub(:best_connector_for).and_yield(Ridley::HostConnector::WinRM)
        end

        it "returns a WinRm worker instance" do
          configured_worker_for.should be_a(Ridley::HostConnector::WinRM::Worker)
        end

        its(:user) { should eq("Administrator") }
        its(:password) { should eq("secret") }
      end
    end

    describe "::merge_data" do
      it "finds the target node and sends it the merge_data message" do
        data = double('data')
        node = double('node')
        node.should_receive(:merge_data).with(data)
        subject.should_receive(:find!).and_return(node)

        subject.merge_data(connection, node, data)
      end
    end
  end

  subject { Ridley::NodeResource.new(connection) }

  describe "#set_chef_attribute" do
    it "sets an normal node attribute at the nested path" do
       subject.set_chef_attribute('deep.nested.item', true)

       subject.normal.should have_key("deep")
       subject.normal["deep"].should have_key("nested")
       subject.normal["deep"]["nested"].should have_key("item")
       subject.normal["deep"]["nested"]["item"].should be_true
    end

    context "when the normal attribute is already set" do
      it "test" do
        subject.normal = {
          deep: {
            nested: {
              item: false
            }
          }
        }
        subject.set_chef_attribute('deep.nested.item', true)
        
        subject.normal["deep"]["nested"]["item"].should be_true
      end
    end
  end

  describe "#cloud?" do
    it "returns true if the cloud automatic attribute is set" do
      subject.automatic = {
        "cloud" => Hash.new
      }

      subject.cloud?.should be_true
    end

    it "returns false if the cloud automatic attribute is not set" do
      subject.automatic.delete(:cloud)

      subject.cloud?.should be_false
    end
  end

  describe "#eucalyptus?" do
    it "returns true if the node is a cloud node using the eucalyptus provider" do
      subject.automatic = {
        "cloud" => {
          "provider" => "eucalyptus"
        }
      }

      subject.eucalyptus?.should be_true
    end

    it "returns false if the node is not a cloud node" do
      subject.automatic.delete(:cloud)

      subject.eucalyptus?.should be_false
    end

    it "returns false if the node is a cloud node but not using the eucalyptus provider" do
      subject.automatic = {
        "cloud" => {
          "provider" => "ec2"
        }
      }

      subject.eucalyptus?.should be_false
    end
  end

  describe "#ec2?" do
    it "returns true if the node is a cloud node using the ec2 provider" do
      subject.automatic = {
        "cloud" => {
          "provider" => "ec2"
        }
      }

      subject.ec2?.should be_true
    end

    it "returns false if the node is not a cloud node" do
      subject.automatic.delete(:cloud)

      subject.ec2?.should be_false
    end

    it "returns false if the node is a cloud node but not using the ec2 provider" do
      subject.automatic = {
        "cloud" => {
          "provider" => "rackspace"
        }
      }

      subject.ec2?.should be_false
    end
  end

  describe "#rackspace?" do
    it "returns true if the node is a cloud node using the rackspace provider" do
      subject.automatic = {
        "cloud" => {
          "provider" => "rackspace"
        }
      }

      subject.rackspace?.should be_true
    end

    it "returns false if the node is not a cloud node" do
      subject.automatic.delete(:cloud)

      subject.rackspace?.should be_false
    end

    it "returns false if the node is a cloud node but not using the rackspace provider" do
      subject.automatic = {
        "cloud" => {
          "provider" => "ec2"
        }
      }

      subject.rackspace?.should be_false
    end
  end

  describe "#cloud_provider" do
    it "returns the cloud provider if the node is a cloud node" do
      subject.automatic = {
        "cloud" => {
          "provider" => "ec2"
        }
      }

      subject.cloud_provider.should eql("ec2")
    end

    it "returns nil if the node is not a cloud node" do
      subject.automatic.delete(:cloud)

      subject.cloud_provider.should be_nil
    end
  end

  describe "#public_ipv4" do
    it "returns the public ipv4 address if the node is a cloud node" do
      subject.automatic = {
        "cloud" => {
          "provider" => "ec2",
          "public_ipv4" => "10.0.0.1"
        }
      }

      subject.public_ipv4.should eql("10.0.0.1")
    end

    it "returns the ipaddress if the node is not a cloud node" do
      subject.automatic = {
        "ipaddress" => "192.168.1.1"
      }
      subject.automatic.delete(:cloud)

      subject.public_ipv4.should eql("192.168.1.1")
    end
  end

  describe "#public_hostname" do
    it "returns the public hostname if the node is a cloud node" do
      subject.automatic = {
        "cloud" => {
          "public_hostname" => "reset.cloud.riotgames.com"
        }
      }

      subject.public_hostname.should eql("reset.cloud.riotgames.com")
    end

    it "returns the FQDN if the node is not a cloud node" do
      subject.automatic = {
        "fqdn" => "reset.internal.riotgames.com"
      }
      subject.automatic.delete(:cloud)

      subject.public_hostname.should eql("reset.internal.riotgames.com")
    end
  end

  describe "#chef_solo" do
    pending
  end

  describe "#chef_client" do
    pending
  end

  describe "#put_secret" do
    pending
  end

  describe "#merge_data" do
    before(:each) do
      subject.name = "reset.riotgames.com"
      subject.should_receive(:update)
    end

    it "appends items to the run_list" do
      subject.merge_data(run_list: ["cook::one", "cook::two"])

      subject.run_list.should =~ ["cook::one", "cook::two"]
    end

    it "ensures the run_list is unique if identical items are given" do
      subject.run_list = [ "cook::one" ]
      subject.merge_data(run_list: ["cook::one", "cook::two"])

      subject.run_list.should =~ ["cook::one", "cook::two"]
    end

    it "deep merges attributes into the normal attributes" do
      subject.normal = {
        one: {
          two: {
            four: :deep
          }
        }
      }
      subject.merge_data(attributes: {
        one: {
          two: {
            three: :deep
          }
        }
      })

      subject.normal[:one][:two].should have_key(:four)
      subject.normal[:one][:two][:four].should eql(:deep)
      subject.normal[:one][:two].should have_key(:three)
      subject.normal[:one][:two][:three].should eql(:deep)
    end
  end
end
