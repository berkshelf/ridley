require 'spec_helper'

describe Ridley::Middleware::ChefAuth do
  let(:server_url) { "https://api.opscode.com/organizations/vialstudios/" }

  describe "ClassMethods" do
    subject { described_class }

    describe "#authentication_headers" do
      let(:client_name) { "reset" }
      let(:client_key) { fixtures_path.join("reset.pem") }

      it "returns a Hash of authentication headers" do
        options = {
          http_method: "GET",
          host: "https://api.opscode.com",
          path: "/something.file"
        }
        subject.authentication_headers(client_name, client_key, options).should be_a(Hash)
      end

      context "when the :client_key is an actual key" do
        let(:client_key) { File.read(fixtures_path.join("reset.pem")) }

        it "returns a Hash of authentication headers" do
          options = {
            http_method: "GET",
            host: "https://api.opscode.com",
            path: "/something.file"
          }
          subject.authentication_headers(client_name, client_key, options).should be_a(Hash)
        end
      end
    end
  end

  subject do
    Faraday.new(server_url) do |conn|
      conn.request :chef_auth, "reset", "/Users/reset/.chef/reset.pem"
      conn.adapter Faraday.default_adapter
    end
  end
end
