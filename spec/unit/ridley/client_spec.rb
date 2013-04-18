require 'spec_helper'

describe Ridley::Client do
  let(:server_url) { "https://api.opscode.com" }
  let(:client_name) { "reset" }
  let(:client_key) { fixtures_path.join("reset.pem").to_s }
  let(:organization) { "vialstudios" }
  let(:encrypted_data_bag_secret_path) { fixtures_path.join("reset.pem").to_s }
  let(:ssh) { {user: "reset", password: "password1", port: "222"} }
  let(:winrm) { {user: "reset", password: "password2", port: "5986"} }
  let(:chef_version) { "10.24.0-01" }

  let(:config) do
    {
      server_url: server_url,
      client_name: client_name,
      client_key: client_key,
      organization: organization,
      encrypted_data_bag_secret_path: encrypted_data_bag_secret_path,
      ssh: ssh,
      winrm: winrm,
      chef_version: chef_version
    }
  end

  describe "ClassMethods" do
    let(:options) do
      {
        server_url: "https://api.opscode.com/some_path",
        client_name: client_name,
        client_key: client_key
      }
    end

    describe "::initialize" do
      subject { described_class.new(options) }

      describe "parsing the 'server_url' option" do
        its(:host) { should eql("api.opscode.com") }
        its(:scheme) { should eql("https") }
        its(:path_prefix) { should eql("/") }
      end

      describe "with a server_url containing an organization" do
        before do
         options[:server_url] = "#{server_url}/organizations/#{organization}"
        end

        it "gets the host data from the server_url" do
          subject.host.should eql("api.opscode.com")
          subject.scheme.should eql("https")
        end

        it "takes the organization out of the server_url and assigns it to the organization reader" do
          subject.organization.should eql(organization)
        end

        it "sets the 'path_prefix' of the connection the organization sub URI" do
          subject.path_prefix.should eql("/organizations/#{organization}")
        end
      end

      it "raises 'ArgumentError' if a value for server_url is not given" do
        expect {
          described_class.new(
            client_name: client_name,
            client_key: client_key
          )
        }.to raise_error(ArgumentError, "Missing required option(s): 'server_url'")
      end

      it "raises if a value for client_name is not given" do
        expect {
          described_class.new(
            server_url: server_url,
            client_key: client_key
          )
        }.to raise_error(ArgumentError, "Missing required option(s): 'client_name'")
      end

      it "raises if a value for client_key is not given" do
        expect {
          described_class.new(
            server_url: server_url,
            client_name: client_name
          )
        }.to raise_error(ArgumentError, "Missing required option(s): 'client_key'")
      end

      it "raises a ClientKeyFileNotFound if the filepath for client_key is not found" do
        config[:client_key] = "/tmp/nofile.xxsa"

        expect {
          described_class.new(config)
        }.to raise_error(Ridley::Errors::ClientKeyFileNotFound)
      end

      it "expands the path of the client_key" do
        config[:client_key] = "~/"

        described_class.new(config).client_key.should_not == "~/"
      end

      it "assigns a 'ssh' attribute from the given 'ssh' option" do
        described_class.new(config).ssh.should eql({user: "reset", password: "password1", port: "222"})
      end

      it "assigns a 'winrm' attribute from the given 'winrm' option" do
        described_class.new(config).winrm.should eql({user: "reset", password: "password2", port: "5986"})
      end

      it "assigns a 'chef_version' attribute from the given 'chef_version' option" do
        described_class.new(config).chef_version.should eql("10.24.0-01")
      end
    end

    describe "::open" do
      it "raises a LocalJumpError if no block is given" do
        lambda {
          described_class.open(config)
        }.should raise_error(LocalJumpError)
      end
    end
  end

  let(:instance) { described_class.new(config) }

  describe "#node" do
    subject { instance.node }

    it { should be_a(Ridley::NodeResource) }

    its(:server_url) { should eql(config[:server_url]) }
    its(:validator_path) { should eql(config[:validator_path]) }
    its(:validator_client) { should eql(config[:validator_client]) }
    its(:encrypted_data_bag_secret) { should eql(instance.encrypted_data_bag_secret) }
    its(:ssh) { should eql(config[:ssh]) }
    its(:winrm) { should eql(config[:winrm]) }
    its(:chef_version) { should eql(config[:chef_version]) }
  end

  describe "#encrypted_data_bag_secret" do
    subject { instance }

    it "returns a string" do
      subject.encrypted_data_bag_secret.should be_a(String)
    end

    context "when a encrypted_data_bag_secret_path is not provided" do
      before(:each) do
        subject.stub(:encrypted_data_bag_secret_path) { nil }
      end

      it "returns nil" do
        subject.encrypted_data_bag_secret.should be_nil
      end
    end

    context "when the file is not found at the given encrypted_data_bag_secret_path" do
      before(:each) do
        subject.stub(:encrypted_data_bag_secret_path) { fixtures_path.join("not.txt").to_s }
      end

      it "raises an EncryptedDataBagSecretNotFound erorr" do
        lambda {
          subject.encrypted_data_bag_secret
        }.should raise_error(Ridley::Errors::EncryptedDataBagSecretNotFound)
      end
    end
  end
end
