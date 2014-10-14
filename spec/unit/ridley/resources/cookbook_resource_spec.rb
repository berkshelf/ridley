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
      it "returns a ResourceNotFound error" do
        expect {
          subject.latest_version(name)
        }.to raise_error(Ridley::Errors::ResourceNotFound)
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
    let(:name) { "artifact" }

    context "when the cookbook has versions" do
      before do
        chef_cookbook(name, "1.0.0")
        chef_cookbook(name, "1.1.0")
        chef_cookbook(name, "1.2.0")
      end

      it "returns an array" do
        subject.versions(name).should be_a(Array)
      end

      it "contains a version string for each cookbook version available" do
        result = subject.versions(name)

        result.should have(3).versions
        result.should include("1.0.0")
        result.should include("1.1.0")
        result.should include("1.2.0")
      end
    end

    context "when the cookbook has no versions" do
      it "raises a ResourceNotFound error" do
        expect {
          subject.versions(name)
        }.to raise_error(Ridley::Errors::ResourceNotFound)
      end
    end
  end

  describe "#satisfy" do
    let(:name) { "ridley_test" }

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
      before { chef_cookbook(name, "1.0.0") }

      it "returns nil" do
        subject.satisfy(name, ">= 2.0.0").should be_nil
      end
    end

    context "when the cookbook does not exist" do
      it "raises a ResourceNotFound error" do
        expect {
          subject.satisfy(name, ">= 1.2.3")
          }.to raise_error(Ridley::Errors::ResourceNotFound)
      end
    end
  end

  describe "#upload" do
    let(:name) { "upload_test" }
    let(:cookbook_path) { fixtures_path.join('example_cookbook') }
    let(:sandbox_resource) { double('sandbox_resource') }
    let(:sandbox) { double('sandbox', upload: nil, commit: nil) }

    before do
      subject.stub(:sandbox_resource).and_return(sandbox_resource)
    end

    it 'does not include files that are ignored' do
      # These are the SHAs for the files. It's not possible to check that
      # the ignored files weren't uploaded, so we just check that the
      # non-ignored files are the ONLY thing uploaded
      sandbox_resource.should_receive(:create).with([
        "211a3a8798d4acd424af15ff8a2e28a5", 
        "4f9051c3ac8031bdaff10300fa92e817", 
        "75077ba33d2887cc1746d1ef716bf8b7", 
        "7b1ebd2ff580ca9dc46fb27ec1653bf2", 
        "84e12365e6f4ebe7db6a0e6a92473b16", 
        "a39eb80def9804f4b118099697cc2cd2", 
        "b70ba735f3af47e5d6fc71b91775b34c", 
        "cafb6869fca13f5c36f24a60de8fb982", 
        "dbf3a6c4ab68a86172be748aced9f46e", 
        "dc6461b5da25775f3ef6a9cc1f6cff9f", 
        "e9a2e24281cfbd6be0a6b1af3b6d277e"
      ]).and_return(sandbox)

      subject.upload(cookbook_path, validate: false)
    end
  end

  describe "#update" do
    pending
  end
end
