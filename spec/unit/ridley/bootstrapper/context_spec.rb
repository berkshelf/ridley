require 'spec_helper'

describe Ridley::Bootstrapper::Context do
  let(:host) { "reset.riotgames.com" }

  let(:options) do
    {
      server_url: "https://api.opscode.com/organizations/vialstudios",
      validator_client: "chef-validator",
      validator_path: fixtures_path.join("reset.pem").to_s,
      encrypted_data_bag_secret_path: fixtures_path.join("reset.pem").to_s
    }
  end

  describe "ClassMethods" do
    subject { Ridley::Bootstrapper::Context }

    describe "::create" do
      
      context "when the best connection is SSH" do
        it "sets template_binding to a Ridley::UnixTemplateBinding" do
          Ridley::Connector.stub(:best_connector_for).and_return(Ridley::Connector::SSH)
          context = subject.create(host, options)
          context.template_binding.should be_a(Ridley::UnixTemplateBinding)
        end
      end

      context "when the best connection is WinRM" do
        it "sets template_binding to a Ridley::WindowsTemplateBinding" do
          Ridley::Connector.stub(:best_connector_for).and_return(Ridley::Connector::WinRM)
          context = subject.create(host, options)
          context.template_binding.should be_a(Ridley::WindowsTemplateBinding)          
        end
      end
    end
  end
end
