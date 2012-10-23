require 'spec_helper'

describe Ridley::Bootstrapper do
  let(:connection) do
    double('conn',
      server_url: "https://api.opscode.com/organizations/vialstudios",
      validator_client: "chef-validator",
      ssh: {
        user: "reset",
        password: "lol"
      }
    )
  end

  let(:nodes) do
    [
      "33.33.33.10"
    ]
  end

  let(:options) do
    {
      validator_path: fixtures_path.join("reset.pem").to_s,
      encrypted_data_bag_secret_path: fixtures_path.join("reset.pem").to_s
    }
  end

  describe "ClassMethods" do
    subject { Ridley::Bootstrapper }

    pending
  end

  subject { Ridley::Bootstrapper.new(connection, nodes, options) }

  describe "#run" do
    pending
  end
end
