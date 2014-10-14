require 'spec_helper'

describe Ridley::Chef::Cookbook do
  describe "ClassMethods" do
    subject { described_class }

    describe "::from_path" do
      let(:cookbook_path) { fixtures_path.join("example_cookbook") }

      it "returns an instance of Ridley::Chef::Cookbook" do
        subject.from_path(cookbook_path).should be_a(described_class)
      end

      it "has a cookbook_name attribute set to the value of the 'name' attribute in the metadata" do
        subject.from_path(cookbook_path).cookbook_name.should eql("example_cookbook")
      end

      context "given a path that does not contain a metadata file" do
        it "raises an IOError" do
          lambda {
            subject.from_path(Dir.mktmpdir)
          }.should raise_error(IOError)
        end
      end

      context "when the metadata does not contain a value for name and no value for :name option was given" do
        let(:cookbook_path) { tmp_path.join("directory_name").to_s }

        before do
          FileUtils.mkdir_p(cookbook_path)
          FileUtils.touch(File.join(cookbook_path, 'metadata.rb'))
        end

        it "raises an exception" do
          expect {
            subject.from_path(cookbook_path)
          }.to raise_error(Ridley::Errors::MissingNameAttribute)
        end
      end

      context "when a metadata.json is missing but metadata.rb is present" do
        let(:cookbook_path) { tmp_path.join("temp_cookbook").to_s }

        before do
          FileUtils.mkdir_p(cookbook_path)
          File.open(File.join(cookbook_path, 'metadata.rb'), 'w+') do |f|
            f.write <<-EOH
              name 'rspec_test'
            EOH
          end
        end

        it "sets the name of the cookbook from the metadata.rb" do
          subject.from_path(cookbook_path).cookbook_name.should eql("rspec_test")
        end
      end

      context "when a metadata.json and metadata.rb are both present" do
        let(:cookbook_path) { tmp_path.join("temp_cookbook").to_s }

        before do
          FileUtils.mkdir_p(cookbook_path)

          File.open(File.join(cookbook_path, 'metadata.json'), 'w+') do |f|
            f.write JSON.fast_generate(name: "json_metadata")
          end

          File.open(File.join(cookbook_path, 'metadata.rb'), 'w+') do |f|
            f.write <<-EOH
              name 'ruby_metadata'
            EOH
          end
        end

        it "prefers the metadata.json" do
          subject.from_path(cookbook_path).cookbook_name.should eql("json_metadata")
        end
      end
    end

    describe "::checksum" do
      it "delegates to Ridley::Chef::Digester.md5_checksum_for_file" do
        path = fixtures_path.join("example_cookbook", "metadata.rb")
        Ridley::Chef::Digester.should_receive(:md5_checksum_for_file).with(path)

        subject.checksum(path)
      end
    end
  end

  let(:cookbook) do
    described_class.from_path(fixtures_path.join('example_cookbook'))
  end

  subject { cookbook }

  describe "#checksums" do
    it "returns a Hash" do
      subject.checksums.should be_a(Hash)
    end

    it "has a key value for every cookbook file" do
      subject.checksums.should have(subject.send(:files).length).items
    end
  end

  describe "#compile_metadata" do
    let(:cookbook_path) { tmp_path.join("temp_cookbook").to_s }
    subject { described_class.from_path(cookbook_path) }
    before do
      FileUtils.mkdir_p(cookbook_path)
      File.open(File.join(cookbook_path, "metadata.rb"), "w+") do |f|
        f.write <<-EOH
          name "rspec_test"
          version "1.2.3"
        EOH
      end
    end

    it "compiles the raw metadata.rb into a metadata.json file in the path of the cookbook" do
      expect(subject.compiled_metadata?).to be_false
      subject.compile_metadata
      subject.reload
      expect(subject.compiled_metadata?).to be_true
      expect(subject.cookbook_name).to eql("rspec_test")
      expect(subject.version).to eql("1.2.3")
    end

    context "when given an output path to write the metadata to" do
      let(:out_path) { tmp_path.join("outpath") }
      before { FileUtils.mkdir_p(out_path) }

      it "writes the compiled metadata to a metadata.json file at the given out path" do
        subject.compile_metadata(out_path)
        expect(File.exist?(File.join(out_path, "metadata.json"))).to be_true
      end
    end
  end

  describe "#compiled_metadata?" do
    let(:cookbook_path) { tmp_path.join("temp_cookbook").to_s }
    subject { described_class.from_path(cookbook_path) }
    before do
      FileUtils.mkdir_p(cookbook_path)
      FileUtils.touch(File.join(cookbook_path, "metadata.rb"))
    end

    context "when a metadata.json file is present" do
      before do
        File.open(File.join(cookbook_path, 'metadata.json'), 'w+') do |f|
          f.write JSON.fast_generate(name: "json_metadata")
        end
      end

      its(:compiled_metadata?) { should be_true }
    end

    context "when a metadata.json file is not present" do
      before do
        FileUtils.rm_f(File.join(cookbook_path, 'metadata.json'))

        File.open(File.join(cookbook_path, 'metadata.rb'), 'w+') do |f|
          f.write "name 'cookbook'"
        end
      end

      its(:compiled_metadata?) { should be_false }
    end
  end

  describe "#manifest" do
    it "returns a Mash with a key for each cookbook file category" do
      [
        :recipes,
        :definitions,
        :libraries,
        :attributes,
        :files,
        :templates,
        :resources,
        :providers,
        :root_files
      ].each do |category|
        subject.manifest.should have_key(category)
      end
    end
  end

  describe "#validate" do
    let(:syntax_checker) { double('syntax_checker') }

    before(:each) do
      subject.stub(:syntax_checker) { syntax_checker }
    end

    it "asks the syntax_checker to validate the ruby and template files of the cookbook" do
      syntax_checker.should_receive(:validate_ruby_files).and_return(true)
      syntax_checker.should_receive(:validate_templates).and_return(true)

      subject.validate
    end

    it "raises CookbookSyntaxError if the cookbook contains invalid ruby files" do
      syntax_checker.should_receive(:validate_ruby_files).and_return(false)

      lambda {
        subject.validate
      }.should raise_error(Ridley::Errors::CookbookSyntaxError)
    end

    it "raises CookbookSyntaxError if the cookbook contains invalid template files" do
      syntax_checker.should_receive(:validate_ruby_files).and_return(true)
      syntax_checker.should_receive(:validate_templates).and_return(false)

      lambda {
        subject.validate
      }.should raise_error(Ridley::Errors::CookbookSyntaxError)
    end
  end

  describe "#file_metadata" do
    let(:file) { subject.path.join("files", "default", "file.h") }
    before(:each) { @metadata = subject.file_metadata(:file, file) }

    it "has a :path key whose value is a relative path from the CachedCookbook's path" do
      @metadata.should have_key(:path)
      @metadata[:path].should be_relative_path
      @metadata[:path].should eql("files/default/file.h")
    end

    it "has a :name key whose value is the basename of the target file" do
      @metadata.should have_key(:name)
      @metadata[:name].should eql("file.h")
    end

    it "has a :checksum key whose value is the checksum of the target file" do
      @metadata.should have_key(:checksum)
      @metadata[:checksum].should eql("7b1ebd2ff580ca9dc46fb27ec1653bf2")
    end

    it "has a :specificity key" do
      @metadata.should have_key(:specificity)
    end

    context "given a file or template in a 'default' directory" do
      let(:file) { subject.path.join("files", "default", "file.h") }
      before(:each) { @metadata = subject.file_metadata(:files, file) }

      it "has a specificity of 'default'" do
        @metadata[:specificity].should eql("default")
      end
    end

    context "given a file or template in a 'ubuntu' directory" do
      let(:file) { subject.path.join("files", "ubuntu", "file.h") }
      before(:each) { @metadata = subject.file_metadata(:files, file) }

      it "has a specificity of 'ubuntu'" do
        @metadata[:specificity].should eql("ubuntu")
      end
    end
  end

  describe "#to_hash" do
    subject { cookbook.to_hash }

    it "has a :frozen? flag" do
      subject.should have_key(:frozen?)
    end

    it "has a :recipes key with a value of an Array Hashes" do
      subject.should have_key(:recipes)
      subject[:recipes].should be_a(Array)
      subject[:recipes].each do |item|
        item.should be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :recipes Array of Hashes" do
      subject[:recipes].first.should have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :recipes Array of Hashes" do
      subject[:recipes].first.should have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :recipes Array of Hashes" do
      subject[:recipes].first.should have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :recipes Array of Hashes" do
      subject[:recipes].first.should have_key(:specificity)
    end

    it "has a :definitions key with a value of an Array Hashes" do
      subject.should have_key(:definitions)
      subject[:definitions].should be_a(Array)
      subject[:definitions].each do |item|
        item.should be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :definitions Array of Hashes" do
      subject[:definitions].first.should have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :definitions Array of Hashes" do
      subject[:definitions].first.should have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :definitions Array of Hashes" do
      subject[:definitions].first.should have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :definitions Array of Hashes" do
      subject[:definitions].first.should have_key(:specificity)
    end

    it "has a :libraries key with a value of an Array Hashes" do
      subject.should have_key(:libraries)
      subject[:libraries].should be_a(Array)
      subject[:libraries].each do |item|
        item.should be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :libraries Array of Hashes" do
      subject[:libraries].first.should have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :libraries Array of Hashes" do
      subject[:libraries].first.should have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :libraries Array of Hashes" do
      subject[:libraries].first.should have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :libraries Array of Hashes" do
      subject[:libraries].first.should have_key(:specificity)
    end

    it "has a :attributes key with a value of an Array Hashes" do
      subject.should have_key(:attributes)
      subject[:attributes].should be_a(Array)
      subject[:attributes].each do |item|
        item.should be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :attributes Array of Hashes" do
      subject[:attributes].first.should have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :attributes Array of Hashes" do
      subject[:attributes].first.should have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :attributes Array of Hashes" do
      subject[:attributes].first.should have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :attributes Array of Hashes" do
      subject[:attributes].first.should have_key(:specificity)
    end

    it "has a :files key with a value of an Array Hashes" do
      subject.should have_key(:files)
      subject[:files].should be_a(Array)
      subject[:files].each do |item|
        item.should be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :files Array of Hashes" do
      subject[:files].first.should have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :files Array of Hashes" do
      subject[:files].first.should have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :files Array of Hashes" do
      subject[:files].first.should have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :files Array of Hashes" do
      subject[:files].first.should have_key(:specificity)
    end

    it "has a :templates key with a value of an Array Hashes" do
      subject.should have_key(:templates)
      subject[:templates].should be_a(Array)
      subject[:templates].each do |item|
        item.should be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :templates Array of Hashes" do
      subject[:templates].first.should have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :templates Array of Hashes" do
      subject[:templates].first.should have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :templates Array of Hashes" do
      subject[:templates].first.should have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :templates Array of Hashes" do
      subject[:templates].first.should have_key(:specificity)
    end

    it "has a :resources key with a value of an Array Hashes" do
      subject.should have_key(:resources)
      subject[:resources].should be_a(Array)
      subject[:resources].each do |item|
        item.should be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :resources Array of Hashes" do
      subject[:resources].first.should have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :resources Array of Hashes" do
      subject[:resources].first.should have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :resources Array of Hashes" do
      subject[:resources].first.should have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :resources Array of Hashes" do
      subject[:resources].first.should have_key(:specificity)
    end

    it "has a :providers key with a value of an Array Hashes" do
      subject.should have_key(:providers)
      subject[:providers].should be_a(Array)
      subject[:providers].each do |item|
        item.should be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :providers Array of Hashes" do
      subject[:providers].first.should have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :providers Array of Hashes" do
      subject[:providers].first.should have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :providers Array of Hashes" do
      subject[:providers].first.should have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :providers Array of Hashes" do
      subject[:providers].first.should have_key(:specificity)
    end

    it "has a :root_files key with a value of an Array Hashes" do
      subject.should have_key(:root_files)
      subject[:root_files].should be_a(Array)
      subject[:root_files].each do |item|
        item.should be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :root_files Array of Hashes" do
      subject[:root_files].first.should have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :root_files Array of Hashes" do
      subject[:root_files].first.should have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :root_files Array of Hashes" do
      subject[:root_files].first.should have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :root_files Array of Hashes" do
      subject[:root_files].first.should have_key(:specificity)
    end

    it "has a :cookbook_name key with a String value" do
      subject.should have_key(:cookbook_name)
      subject[:cookbook_name].should be_a(String)
    end

    it "has a :metadata key with a Hashie::Mash value" do
      subject.should have_key(:metadata)
      subject[:metadata].should be_a(Hashie::Mash)
    end

    it "has a :version key with a String value" do
      subject.should have_key(:version)
      subject[:version].should be_a(String)
    end

    it "has a :name key with a String value" do
      subject.should have_key(:name)
      subject[:name].should be_a(String)
    end

    it "has a value containing the cookbook name and version separated by a dash for :name" do
      name, version = subject[:name].split('-')

      name.should eql(cookbook.cookbook_name)
      version.should eql(cookbook.version)
    end

    it "has a :chef_type key with Cookbook::CHEF_TYPE as the value" do
      subject.should have_key(:chef_type)
      subject[:chef_type].should eql(Ridley::Chef::Cookbook::CHEF_TYPE)
    end
  end

  describe "#to_json" do
    before(:each) do
      @json = subject.to_json
    end

    it "has a 'json_class' key with Cookbook::CHEF_JSON_CLASS  as the value" do
      @json.should have_json_path('json_class')
      parse_json(@json)['json_class'].should eql(Ridley::Chef::Cookbook::CHEF_JSON_CLASS)
    end

    it "has a 'frozen?' flag" do
      @json.should have_json_path('frozen?')
    end
  end
end
