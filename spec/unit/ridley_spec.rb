require 'spec_helper'

describe Ridley do
  let(:server_url) { "https://api.opscode.com/organizations/vialstudios/" }
  let(:client_name) { "reset" }
  let(:client_key) { "/Users/reset/.chef/reset.pem" }

  describe "ClassMethods" do
    subject { Ridley }

    describe "::start" do
      it "creates a new connection and passes a block to it" do
        conn = double('conn')
        conn.should_receive(:start).and_yield
        subject.should_receive(:connection).with(server_url, client_name, client_key).and_return(conn)

        subject.start(server_url, client_name, client_key) do; end
      end
    end

    describe "::connection" do
      it "returns a connection object" do
        subject.connection(server_url, client_name, client_key).should be_a(Ridley::Connection)
      end
    end
  end
end
