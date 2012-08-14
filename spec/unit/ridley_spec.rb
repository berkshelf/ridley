require 'spec_helper'

describe Ridley do
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
    subject { Ridley }

    describe "::start" do
      it "creates a new connection and passes a block to it" do
        conn = double('conn')
        conn.should_receive(:start).and_yield
        subject.should_receive(:connection).with(config).and_return(conn)

        subject.start(config) do; end
      end
    end

    describe "::connection" do
      it "returns a connection object" do
        subject.connection(config).should be_a(Ridley::Connection)
      end
    end
  end
end
