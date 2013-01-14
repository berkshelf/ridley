require 'spec_helper'

describe Ridley::Client do
  let(:server_url) { "https://api.opscode.com" }
  let(:client_name) { "reset" }
  let(:client_key) { fixtures_path.join("reset.pem").to_s }
  let(:organization) { "vialstudios" }
  let(:encrypted_data_bag_secret_path) { fixtures_path.join("reset.pem").to_s }

  let(:config) do
    {
      server_url: server_url,
      client_name: client_name,
      client_key: client_key,
      organization: organization,
      encrypted_data_bag_secret_path: encrypted_data_bag_secret_path
    }
  end

  describe "ClassMethods" do
    subject { described_class }

    describe "::initialize" do
      let(:server_url) { "https://api.opscode.com/some_path" }

      describe "parsing the 'server_url' option" do
        before(:each) do
          @conn = subject.new(
            server_url: server_url,
            client_name: client_name,
            client_key: client_key
          )
        end

        it "assigns a 'host' attribute from the given 'server_url' option" do
          @conn.host.should eql("api.opscode.com")
        end

        it "assigns a 'scheme' attribute from the given 'server_url' option" do
          @conn.scheme.should eql("https")
        end

        it "sets a 'path_prefix' to the root of the given 'server_url' option" do
          @conn.path_prefix.should eql("/")
        end
      end

      describe "with a server_url containing an organization" do
        before(:each) do
          @conn = subject.new(
            server_url: "#{server_url}/organizations/#{organization}",
            client_name: client_name,
            client_key: client_key
          )
        end

        it "gets the host data from the server_url" do
          @conn.host.should eql("api.opscode.com")
          @conn.scheme.should eql("https")
        end

        it "assigns the value of the 'organization' option to an 'organization' attribute" do
          @conn.connection.organization.should eql(organization)
        end

        it "sets the 'path_prefix' of the connection the organization sub URI" do
          @conn.path_prefix.should eql("/organizations/#{organization}")
        end
      end

      it "raises 'ArgumentError' if a value for server_url is not given" do
        lambda {
          subject.new(
            client_name: client_name,
            client_key: client_key
          )
        }.should raise_error(ArgumentError, "Missing required option(s): 'server_url'")
      end

      it "raises if a value for client_name is not given" do
        lambda {
          subject.new(
            server_url: server_url,
            client_key: client_key
          )
        }.should raise_error(ArgumentError, "Missing required option(s): 'client_name'")
      end

      it "raises if a value for client_key is not given" do
        lambda {
          subject.new(
            server_url: server_url,
            client_name: client_name
          )
        }.should raise_error(ArgumentError, "Missing required option(s): 'client_key'")
      end

      it "raises a ClientKeyFileNotFound if the filepath for client_key is not found" do
        config[:client_key] = "/tmp/nofile.xxsa"

        lambda {
          subject.new(config)
        }.should raise_error(Ridley::Errors::ClientKeyFileNotFound)
      end

      it "expands the path of the client_key" do
        config[:client_key] = "~/"

        subject.new(config).client_key.should_not == "~/"
      end
    end

    describe "::open" do
      it "raises a LocalJumpError if no block is given" do
        lambda {
          subject.open(config)
        }.should raise_error(LocalJumpError)
      end
    end
  end

  subject do
    described_class.new(config)
  end

  describe "#encrypted_data_bag_secret" do
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
