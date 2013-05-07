require 'spec_helper'

describe Ridley::EnvironmentResource do
  let(:server_url)  { Ridley::RSpec::ChefServer.server_url }
  let(:client_name) { "reset" }
  let(:client_key)  { fixtures_path.join('reset.pem').to_s }
  let(:connection)  { Ridley::Connection.new(server_url, client_name, client_key) }

  let(:resource) do
    resource = described_class.new(double('registry'))
    resource.stub(connection: connection)
    resource
  end

  subject { resource }

  describe "#cookbook_versions" do
    let(:name) { "rspec-test" }
    let(:run_list) { ["hello", "there"] }

    subject { resource.cookbook_versions(name, run_list) }

    context "when the chef server has the given cookbooks" do
      before do
        chef_environment("rspec-test")
        chef_cookbook("hello", "1.2.3")
        chef_cookbook("there", "1.0.0")
      end

      it "returns a Hash" do
        should be_a(Hash)
      end

      it "contains a key for each cookbook" do
        subject.keys.should have(2).items
        subject.should have_key("hello")
        subject.should have_key("there")
      end
    end

    context "when the chef server does not have the environment" do
      before do
        chef_cookbook("hello", "1.2.3")
        chef_cookbook("there", "1.0.0")
      end

      it "raises a ResourceNotFound error" do
        expect { subject }.to raise_error(Ridley::Errors::ResourceNotFound)
      end
    end

    context "when the chef server does not have one or more of the cookbooks" do
      it "raises a precondition failed error" do
        expect { subject }.to raise_error(Ridley::Errors::HTTPPreconditionFailed)
      end
    end
  end

  describe "#delete_all" do
    let(:default_env) { double(name: "_default") }
    let(:destroy_env) { double(name: "destroy_me") }

    before do
      subject.stub(all: [ default_env, destroy_env ])
    end

    it "does not destroy the '_default' environment" do
      subject.stub(future: double('future', value: nil))
      subject.should_not_receive(:future).with(:delete, default_env)

      subject.delete_all
    end
  end
end
