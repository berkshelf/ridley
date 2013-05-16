require 'spec_helper'

describe Ridley::CookbookObject do
  let(:connection) { double('connection') }
  let(:resource) { double('resource', connection: connection) }
  subject { described_class.new(resource) }

  describe "#download" do
    it "downloads each file" do
      subject.stub(:manifest) do
        {
          resources: [],
          providers: [],
          recipes: [
            {
              checksum: "aa3505d3eb8ce328ea84a4333df05b07",
              name: "default.rb",
              path: "recipes/default.rb",
              specificity: "default",
              url: "https://chef.lax1.riotgames.com/organizations/reset/cookbooks/ohai/1.0.2/files/aa3505d3eb8ce328ea84a4333df05b07"
            }
          ],
          definitions: [],
          libraries: [],
          attributes: [],
          files: [
            {
              checksum: "85bc3bb921efade3f2566a668ab4b639",
              name: "README",
              path: "files/default/plugins/README",
              specificity: "plugins",
              url: "https://chef.lax1.riotgames.com/organizations/reset/cookbooks/ohai/1.0.2/files/85bc3bb921efade3f2566a668ab4b639"
            }
          ],
          templates: [],
          root_files: []
        }
      end

      subject.should_receive(:download_file).with(:recipes, "recipes/default.rb", anything)
      subject.should_receive(:download_file).with(:files, "files/default/plugins/README", anything)

      subject.download
    end
  end

  describe "#download_file" do
    let(:destination) { tmp_path.join('fake.file').to_s }

    before(:each) do
      subject.stub(:root_files) { [ { path: 'metadata.rb', url: "http://test.it/file" } ] }
    end

    it "downloads the file from the file's url" do
      connection.should_receive(:stream).with("http://test.it/file", destination)

      subject.download_file(:root_file, "metadata.rb", destination)
    end

    context "when given an unknown filetype" do
      it "raises an UnknownCookbookFileType error" do
        expect {
          subject.download_file(:not_existant, "default.rb", destination)
        }.to raise_error(Ridley::Errors::UnknownCookbookFileType)
      end
    end

    context "when the cookbook doesn't have the specified file" do
      before(:each) do
        subject.stub(:root_files) { Array.new }
      end

      it "returns nil" do
        subject.download_file(:root_file, "metadata.rb", destination).should be_nil
      end
    end
  end

  describe "#manifest" do
    it "returns a Hash" do
      subject.manifest.should be_a(Hash)
    end

    it "has a key for each item in FILE_TYPES" do
      subject.manifest.keys.should =~ described_class::FILE_TYPES
    end

    it "contains an empty array for each key" do
      subject.manifest.should each be_a(Array)
      subject.manifest.values.should each be_empty
    end
  end

  describe "#reload" do
    it "returns the updated self" do
      other = subject.dup
      other.version = "1.2.3"
      resource.should_receive(:find).with(subject, subject.version).and_return(other)

      expect(subject.reload).to eq(other)
    end
  end
end
