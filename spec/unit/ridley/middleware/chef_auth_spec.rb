require 'spec_helper'

describe Ridley::Middleware::ChefAuth do
  let(:server_url) { "https://api.opscode.com/organizations/vialstudios/" }

  subject do
    Faraday.new(server_url) do |conn|
      conn.request :chef_auth, "reset", "/Users/reset/.chef/reset.pem"
      conn.adapter Faraday.default_adapter
    end
  end

  pending
end
