require 'spec_helper'

describe Ridley::CookbookResource do
  let(:connection) { double('connection') }
  subject { described_class.new(double('registry')) }
  before  { subject.stub(connection: connection) }

  describe "#download" do
    pending
  end

  describe "#latest_version" do
    let(:name) { "ant" }

    before(:each) do
      subject.should_receive(:versions).with(name).and_return(versions)
    end

    context "when the cookbook has no versions" do
      let(:versions) { Array.new }

      it "returns nil" do
        subject.latest_version(name).should be_nil
      end
    end

    context "when the cookbook has versions" do
      let(:versions) do
        [ "1.0.0", "1.2.0", "3.0.0", "1.4.1" ]
      end

      it "returns nil" do
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
    pending
  end

  describe "#upload" do
    pending
  end

  describe "#update" do
    pending
  end
end
