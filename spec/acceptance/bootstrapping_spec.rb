require 'spec_helper'

describe "Bootstrapping a node", type: "acceptance" do
  let(:server_url) { "https://api.opscode.com" }
  let(:client_name) { "reset" }
  let(:client_key) { "/Users/reset/.chef/reset.pem" }
  let(:organization) { "vialstudios" }

  let(:connection) do
    Ridley.new(
      server_url: server_url,
      client_name: client_name,
      client_key: client_key,
      organization: organization,
      validator_client: "vialstudios-validator",
      validator_path: "/Users/reset/.chef/vialstudios-validator.pem",
      ssh: {
        user: "vagrant",
        password: "vagrant"
      }
    )
  end

  it "returns an array of response objects" do
    pending
    
    connection.node.bootstrap("33.33.33.10").should_not have_errors
  end
end
