require 'spec_helper'

describe Ridley::CookbookResource do
  let(:client) { double('client') }

  subject { described_class.new(client) }

  describe "#download_file" do
    let(:destination) { tmp_path.join('fake.file') }

    before(:each) do
      subject.stub(:root_files) { [double('file', name: 'metadata.rb', url: "http://test.it/file")] }
    end

    it "downloads the file from the file's url" do
      pending
      
      subject.download_file(:root_file, "metadata.rb", destination)
    end

    context "when given 'attribute' for filetype" do
      it "raises an InternalError" do
        expect {
          subject.download_file(:attribute, "default.rb", destination)
        }.to raise_error(Ridley::Errors::InternalError)
      end
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
end
