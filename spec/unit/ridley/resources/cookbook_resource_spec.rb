require 'spec_helper'

describe Ridley::CookbookResource do
  let(:client_name) { "reset" }
  let(:client_key) { fixtures_path.join('reset.pem') }
  let(:connection) { Ridley::Connection.new("http://localhost:8889", "reset", fixtures_path.join("reset.pem").to_s) }
  subject { described_class.new(double('registry'), client_name, client_key) }
  before  { subject.stub(connection: connection) }

  describe "#download" do
    let(:name) { "example_cookbook" }
    let(:version) { "0.1.0" }
    let(:destination) { tmp_path.join("example_cookbook-0.1.0").to_s }

    context "when the cookbook of the name/version is found" do
      it "downloads the cookbook to the destination" do
        pending "can't test downloading until https://github.com/jkeiser/chef-zero/issues/5 is fixed"
      end
    end

    context "when the cookbook of the name/version is not found" do
      before { subject.should_receive(:find).with(name, version).and_return(nil) }

      it "raises a ResourceNotFound error" do
        expect {
          subject.download(name, version, destination)
        }.to raise_error(Ridley::Errors::ResourceNotFound)
      end
    end
  end

  describe "#latest_version" do
    let(:name) { "ant" }

    context "when the cookbook has no versions" do
      it "returns nil" do
        subject.latest_version(name).should be_nil
      end
    end

    context "when the cookbook has versions" do
      before do
        chef_cookbook(name, "1.0.0")
        chef_cookbook(name, "1.2.0")
        chef_cookbook(name, "3.0.0")
      end

      it "returns the latest version" do
        subject.latest_version(name).should eql("3.0.0")
      end
    end
  end

  describe "#versions" do
    let(:cookbook) { "artifact" }
    let(:versions_path) { "#{described_class.resource_path}/#{cookbook}" }
    let(:response) do
      double(body: {
        cookbook => {
          "versions" => [
            {
              "url" => "https://api.opscode.com/organizations/ridley/cookbooks/artifact/1.0.0",
              "version" => "1.0.0"
            },
            {
              "url" => "https://api.opscode.com/organizations/ridley/cookbooks/artifact/1.1.0",
              "version" => "1.1.0"
            },
            {
              "url" => "https://api.opscode.com/organizations/ridley/cookbooks/artifact/1.2.0",
              "version" => "1.2.0"
            }
          ],
          "url" => "https://api.opscode.com/organizations/ridley/cookbooks/artifact"
        }
      })
    end

    before(:each) do
      connection.should_receive(:get).with(versions_path).and_return(response)
    end

    it "returns an array" do
      subject.versions(cookbook).should be_a(Array)
    end

    it "contains a version string for each cookbook version available" do
      result = subject.versions(cookbook)

      result.should have(3).versions
      result.should include("1.0.0")
      result.should include("1.1.0")
      result.should include("1.2.0")
    end
  end

  describe "#satisfy" do
    let(:name) { "ridley_test" }

    before { chef_cookbook(name, "1.0.0") }

    context "when there is a solution" do
      before do
        chef_cookbook(name, "2.0.0")
        chef_cookbook(name, "3.0.0")
      end

      it "returns a CookbookObject" do
        subject.satisfy(name, ">= 2.0.0").should be_a(Ridley::CookbookObject)
      end

      it "is the best solution" do
        subject.satisfy(name, ">= 2.0.0").version.should eql("3.0.0")
      end
    end

    context "when there is no solution" do
      it "returns nil" do
        subject.satisfy(name, ">= 2.0.0").should be_nil
      end
    end

    context "when the cookbook does not exist" do
      it "returns nil" do
        subject.satisfy(name, ">= 1.2.3").should be_nil
      end
    end
  end

  describe "#upload" do
    pending
  end

  describe "#update" do
    pending
  end
end
