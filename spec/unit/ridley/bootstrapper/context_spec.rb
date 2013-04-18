require 'spec_helper'

describe Ridley::Bootstrapper::Context do
  let(:host) { "reset.riotgames.com" }

  let(:options) do
    {
      server_url: "https://api.opscode.com/organizations/vialstudios",
      validator_client: "chef-validator",
      validator_path: fixtures_path.join("reset.pem").to_s,
      encrypted_data_bag_secret: File.read(fixtures_path.join("reset.pem"))
    }
  end

  describe "ClassMethods" do
    subject { Ridley::Bootstrapper::Context }

    describe "::create" do
      context "when the best connection is SSH" do
        it "sets template_binding to a Ridley::UnixTemplateBinding" do
          Ridley::HostConnector.stub(:best_connector_for).and_return(Ridley::HostConnector::SSH)
          context = subject.create(host, options)
          context.template_binding.should be_a(Ridley::UnixTemplateBinding)
        end
      end

      context "when the best connection is WinRM" do
        it "sets template_binding to a Ridley::WindowsTemplateBinding" do
          Ridley::HostConnector.stub(:best_connector_for).and_return(Ridley::HostConnector::WinRM)
          context = subject.create(host, options)
          context.template_binding.should be_a(Ridley::WindowsTemplateBinding)
        end
      end

      context "when there is no good connection option" do
        it "raises an error" do
          Ridley::HostConnector.stub(:best_connector_for).and_return(nil)
          expect {
            context = subject.create(host, options)
          }.to raise_error(Ridley::Errors::HostConnectionError)
        end
      end
    end
  end
end
