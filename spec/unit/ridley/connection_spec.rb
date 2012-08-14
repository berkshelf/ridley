require 'spec_helper'

describe Ridley::Connection do
  let(:server_url) { "https://api.opscode.com" }
  let(:client_name) { "reset" }
  let(:client_key) { "/Users/reset/.chef/reset.pem" }
  let(:organization) { "vialstudios" }

  let(:config) do
    {
      server_url: server_url,
      client_name: client_name,
      client_key: client_key,
      organization: organization
    }
  end

  describe "ClassMethods" do
    subject { Ridley::Connection }

    before(:each) do
      @original_conn = subject.active
    end

    after(:each) do
      subject.active = @original_conn
    end

    describe "::initialize" do
      let(:server_url) { "https://api.opscode.com/some_path" }

      describe "parsing the 'server_url' option" do
        before(:each) do
          @conn = subject.new(server_url: server_url, client_name: client_name, client_key: client_key)
        end

        it "assigns a 'host' attribute from the given 'server_url' option" do
          @conn.host.should eql("api.opscode.com")
        end

        it "assigns a 'scheme' attribute from the given 'server_url' option" do
          @conn.scheme.should eql("https")
        end

        it "throws away the 'path' from the given 'server_url' option" do
          @conn.path.should eql("/")
        end
      end

      describe "specifying an 'organization' option" do
        before(:each) do
          @conn = subject.new(
            server_url: server_url,
            client_name: client_name,
            client_key: client_key,
            organization: organization
          )
        end

        it "assigns the value of the 'organization' option to an 'organization' attribute" do
          @conn.organization.should eql(organization)
        end

        it "sets the path of the connection to '/organizations/{org_name}'" do
          @conn.path.should eql("/organizations/#{organization}")
        end
      end

      it "raises 'ArgumentError' if a value for server_url is not given" do
        lambda {
          subject.new(
            client_name: client_name,
            client_key: client_key
          )
        }.should raise_error(ArgumentError, "missing required option(s): 'server_url'")
      end

      it "raises if a value for client_name is not given" do
        lambda {
          subject.new(
            server_url: server_url,
            client_key: client_key
          )
        }.should raise_error(ArgumentError, "missing required option(s): 'client_name'")
      end

      it "raises if a value for client_key is not given" do
        lambda {
          subject.new(
            server_url: server_url,
            client_name: client_name
          )
        }.should raise_error(ArgumentError, "missing required option(s): 'client_key'")
      end
    end

    describe "::start" do
      it "creates a new instance of Ridley::Connection and sets it to the active connection" do
        subject.start(config) do
          Ridley::Connection.active.should_not be_nil
        end
      end

      it "sets the Ridley::Connection.active to the original after the block ends" do
        subject.active = :fake
        subject.start(config) do; end

        subject.active.should eql(:fake)
      end

      it "raises a Ridley::Errors::InternalError if no block is given" do
        lambda {
          subject.start(config)
        }.should raise_error(Ridley::Errors::InternalError)
      end
    end
  end

  subject do
    Ridley::Connection.new(config)
  end

  describe "#start" do
    before(:each) do
      @original_conn = Ridley::Connection.active
    end

    after(:each) do
      Ridley::Connection.active = @original_conn
    end

    it "sets the Ridley::Connection.active to self" do
      subject.start do
        Ridley::Connection.active.should eql(subject)
      end
    end

    it "sets the Ridley::Connection.active to the original after the block ends" do
      subject.class.active = :fake
      subject.start do; end

      Ridley::Connection.active.should eql(:fake)
    end

    it "raises a Ridley::Errors::InternalError if no block is given" do
      lambda {
        subject.start
      }.should raise_error(Ridley::Errors::InternalError)
    end

    describe "#environment" do
      it "it returns the Ridley::Environment class" do
        subject.start do
          environment.should eql(Ridley::Environment)
        end
      end
    end

    describe "HTTP Request" do
      describe "#get" do
        it "appends the given path to the connection's server_uri path and sends a get request to it" do
          stub_request(:get, "https://api.opscode.com:80/organizations/vialstudios/cookbooks").
            to_return(status: 200, body: "{}")

          subject.get("cookbooks")
        end
      end

      describe "#put" do
        it "appends the given path to the connection's server_uri path and sends a put request to it" do
          stub_request(:put, "https://api.opscode.com:80/organizations/vialstudios/cookbooks").
            with(body: "content").
            to_return(status: 200, body: "{}")

          subject.put("cookbooks", "content")
        end
      end

      describe "#post" do
        it "appends the given path to the connection's server_uri path and sends a post request to it" do
          stub_request(:post, "https://api.opscode.com:80/organizations/vialstudios/cookbooks").
            with(body: "content").
            to_return(status: 200, body: "{}")

          subject.post("cookbooks", "content")
        end
      end

      describe "#delete" do
        it "appends the given path to the connection's server_uri path and sends a delete request to it" do
          stub_request(:delete, "https://api.opscode.com:80/organizations/vialstudios/cookbooks/nginx").
            to_return(status: 200, body: "{}")

          subject.delete("cookbooks/nginx")
        end
      end
    end

    describe "api_type" do
      it "returns :foss if the organization is not set" do
        subject.stub(:organization).and_return(nil)

        subject.api_type.should eql(:foss)
      end

      it "returns :hosted if the organization is set" do
        subject.stub(:organization).and_return("vialstudios")

        subject.api_type.should eql(:hosted)
      end
    end
  end
end
