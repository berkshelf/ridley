require 'spec_helper'

describe Ridley::Chef::Cookbook do
  describe "ClassMethods" do
    subject { described_class }

    describe "::from_path" do
      let(:cookbook_path) { fixtures_path.join("example_cookbook") }

      it "returns an instance of Ridley::Chef::Cookbook" do
        expect(subject.from_path(cookbook_path)).to be_a(described_class)
      end

      it "has a cookbook_name attribute set to the value of the 'name' attribute in the metadata" do
        expect(subject.from_path(cookbook_path).cookbook_name).to eql("example_cookbook")
      end

      context "given a path that does not contain a metadata file" do
        it "raises an IOError" do
          expect {
            subject.from_path(Dir.mktmpdir)
          }.to raise_error(IOError)
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
          expect(subject.from_path(cookbook_path).cookbook_name).to eql("rspec_test")
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
          expect(subject.from_path(cookbook_path).cookbook_name).to eql("json_metadata")
        end
      end
    end

    describe "::checksum" do
      it "delegates to Ridley::Chef::Digester.md5_checksum_for_file" do
        path = fixtures_path.join("example_cookbook", "metadata.rb")
        expect(Ridley::Chef::Digester).to receive(:md5_checksum_for_file).with(path)

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
      expect(subject.checksums).to be_a(Hash)
    end

    it "has a key value for every cookbook file" do
      expect(subject.checksums.size).to eq(subject.send(:files).length)
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
      expect(subject.compiled_metadata?).to be_falsey
      subject.compile_metadata
      subject.reload
      expect(subject.compiled_metadata?).to be_truthy
      expect(subject.cookbook_name).to eql("rspec_test")
      expect(subject.version).to eql("1.2.3")
    end

    context "when given an output path to write the metadata to" do
      let(:out_path) { tmp_path.join("outpath") }
      before { FileUtils.mkdir_p(out_path) }

      it "writes the compiled metadata to a metadata.json file at the given out path" do
        subject.compile_metadata(out_path)
        expect(File.exist?(File.join(out_path, "metadata.json"))).to be_truthy
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

      describe '#compiled_metadata?' do
        subject { super().compiled_metadata? }
        it { is_expected.to be_truthy }
      end
    end

    context "when a metadata.json file is not present" do
      before do
        FileUtils.rm_f(File.join(cookbook_path, 'metadata.json'))

        File.open(File.join(cookbook_path, 'metadata.rb'), 'w+') do |f|
          f.write "name 'cookbook'"
        end
      end

      describe '#compiled_metadata?' do
        subject { super().compiled_metadata? }
        it { is_expected.to be_falsey }
      end
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
        expect(subject.manifest).to have_key(category)
      end
    end
  end

  describe "#validate" do
    let(:syntax_checker) { double('syntax_checker') }

    before(:each) do
      allow(subject).to receive(:syntax_checker) { syntax_checker }
    end

    it "asks the syntax_checker to validate the ruby and template files of the cookbook" do
      expect(syntax_checker).to receive(:validate_ruby_files).and_return(true)
      expect(syntax_checker).to receive(:validate_templates).and_return(true)

      subject.validate
    end

    it "raises CookbookSyntaxError if the cookbook contains invalid ruby files" do
      expect(syntax_checker).to receive(:validate_ruby_files).and_return(false)

      expect {
        subject.validate
      }.to raise_error(Ridley::Errors::CookbookSyntaxError)
    end

    it "raises CookbookSyntaxError if the cookbook contains invalid template files" do
      expect(syntax_checker).to receive(:validate_ruby_files).and_return(true)
      expect(syntax_checker).to receive(:validate_templates).and_return(false)

      expect {
        subject.validate
      }.to raise_error(Ridley::Errors::CookbookSyntaxError)
    end
  end

  describe "#file_metadata" do
    let(:file) { subject.path.join("files", "default", "file.h") }
    before(:each) { @metadata = subject.file_metadata(:file, file) }

    it "has a :path key whose value is a relative path from the CachedCookbook's path" do
      expect(@metadata).to have_key(:path)
      expect(@metadata[:path]).to be_relative_path
      expect(@metadata[:path]).to eql("files/default/file.h")
    end

    it "has a :name key whose value is the basename of the target file" do
      expect(@metadata).to have_key(:name)
      expect(@metadata[:name]).to eql("file.h")
    end

    it "has a :checksum key whose value is the checksum of the target file" do
      expect(@metadata).to have_key(:checksum)
      expect(@metadata[:checksum]).to eql("7b1ebd2ff580ca9dc46fb27ec1653bf2")
    end

    it "has a :specificity key" do
      expect(@metadata).to have_key(:specificity)
    end

    context "given a file or template in a 'default' directory" do
      let(:file) { subject.path.join("files", "default", "file.h") }
      before(:each) { @metadata = subject.file_metadata(:files, file) }

      it "has a specificity of 'default'" do
        expect(@metadata[:specificity]).to eql("default")
      end
    end

    context "given a file or template in a 'ubuntu' directory" do
      let(:file) { subject.path.join("files", "ubuntu", "file.h") }
      before(:each) { @metadata = subject.file_metadata(:files, file) }

      it "has a specificity of 'ubuntu'" do
        expect(@metadata[:specificity]).to eql("ubuntu")
      end
    end
  end

  describe "#file_specificity" do
    let(:category) { :templates }
    let(:relpath) { 'default.rb' }
    let(:file) { subject.path.join(category.to_s, relpath) }
    before(:each) { @specificity = subject.file_specificity(category, file) }

    context "given a recipe file" do
      let(:category) { :recipes }

      it "has a specificity of 'default'" do
        expect(@specificity).to eql("default")
      end
    end

    context "given a template 'default/config.erb'" do
      let(:relpath) { 'default/config.erb' }

      it "has a specificity of 'default'" do
        expect(@specificity).to eql("default")
      end
    end

    context "given a template 'centos/config.erb'" do
      let(:relpath) { 'centos/config.erb' }

      it "has a specificity of 'centos'" do
        expect(@specificity).to eql("centos")
      end
    end

    context "given a template 'config.erb'" do
      let(:relpath) { 'config.erb' }

      it "has a specificity of 'root_default'" do
        expect(@specificity).to eql("root_default")
      end
    end
  end

  describe "#to_hash" do
    subject { cookbook.to_hash }

    it "has a :frozen? flag" do
      expect(subject).to have_key(:frozen?)
    end

    it "has a :recipes key with a value of an Array Hashes" do
      expect(subject).to have_key(:recipes)
      expect(subject[:recipes]).to be_a(Array)
      subject[:recipes].each do |item|
        expect(item).to be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :recipes Array of Hashes" do
      expect(subject[:recipes].first).to have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :recipes Array of Hashes" do
      expect(subject[:recipes].first).to have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :recipes Array of Hashes" do
      expect(subject[:recipes].first).to have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :recipes Array of Hashes" do
      expect(subject[:recipes].first).to have_key(:specificity)
    end

    it "has a :definitions key with a value of an Array Hashes" do
      expect(subject).to have_key(:definitions)
      expect(subject[:definitions]).to be_a(Array)
      subject[:definitions].each do |item|
        expect(item).to be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :definitions Array of Hashes" do
      expect(subject[:definitions].first).to have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :definitions Array of Hashes" do
      expect(subject[:definitions].first).to have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :definitions Array of Hashes" do
      expect(subject[:definitions].first).to have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :definitions Array of Hashes" do
      expect(subject[:definitions].first).to have_key(:specificity)
    end

    it "has a :libraries key with a value of an Array Hashes" do
      expect(subject).to have_key(:libraries)
      expect(subject[:libraries]).to be_a(Array)
      subject[:libraries].each do |item|
        expect(item).to be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :libraries Array of Hashes" do
      expect(subject[:libraries].first).to have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :libraries Array of Hashes" do
      expect(subject[:libraries].first).to have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :libraries Array of Hashes" do
      expect(subject[:libraries].first).to have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :libraries Array of Hashes" do
      expect(subject[:libraries].first).to have_key(:specificity)
    end

    it "has a :attributes key with a value of an Array Hashes" do
      expect(subject).to have_key(:attributes)
      expect(subject[:attributes]).to be_a(Array)
      subject[:attributes].each do |item|
        expect(item).to be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :attributes Array of Hashes" do
      expect(subject[:attributes].first).to have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :attributes Array of Hashes" do
      expect(subject[:attributes].first).to have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :attributes Array of Hashes" do
      expect(subject[:attributes].first).to have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :attributes Array of Hashes" do
      expect(subject[:attributes].first).to have_key(:specificity)
    end

    it "has a :files key with a value of an Array Hashes" do
      expect(subject).to have_key(:files)
      expect(subject[:files]).to be_a(Array)
      subject[:files].each do |item|
        expect(item).to be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :files Array of Hashes" do
      expect(subject[:files].first).to have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :files Array of Hashes" do
      expect(subject[:files].first).to have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :files Array of Hashes" do
      expect(subject[:files].first).to have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :files Array of Hashes" do
      expect(subject[:files].first).to have_key(:specificity)
    end

    it "has a :templates key with a value of an Array Hashes" do
      expect(subject).to have_key(:templates)
      expect(subject[:templates]).to be_a(Array)
      subject[:templates].each do |item|
        expect(item).to be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :templates Array of Hashes" do
      expect(subject[:templates].first).to have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :templates Array of Hashes" do
      expect(subject[:templates].first).to have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :templates Array of Hashes" do
      expect(subject[:templates].first).to have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :templates Array of Hashes" do
      expect(subject[:templates].first).to have_key(:specificity)
    end

    it "has a :resources key with a value of an Array Hashes" do
      expect(subject).to have_key(:resources)
      expect(subject[:resources]).to be_a(Array)
      subject[:resources].each do |item|
        expect(item).to be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :resources Array of Hashes" do
      expect(subject[:resources].first).to have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :resources Array of Hashes" do
      expect(subject[:resources].first).to have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :resources Array of Hashes" do
      expect(subject[:resources].first).to have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :resources Array of Hashes" do
      expect(subject[:resources].first).to have_key(:specificity)
    end

    it "has a :providers key with a value of an Array Hashes" do
      expect(subject).to have_key(:providers)
      expect(subject[:providers]).to be_a(Array)
      subject[:providers].each do |item|
        expect(item).to be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :providers Array of Hashes" do
      expect(subject[:providers].first).to have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :providers Array of Hashes" do
      expect(subject[:providers].first).to have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :providers Array of Hashes" do
      expect(subject[:providers].first).to have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :providers Array of Hashes" do
      expect(subject[:providers].first).to have_key(:specificity)
    end

    it "has a :root_files key with a value of an Array Hashes" do
      expect(subject).to have_key(:root_files)
      expect(subject[:root_files]).to be_a(Array)
      subject[:root_files].each do |item|
        expect(item).to be_a(Hash)
      end
    end

    it "has a :name key value pair in a Hash of the :root_files Array of Hashes" do
      expect(subject[:root_files].first).to have_key(:name)
    end

    it "has a :path key value pair in a Hash of the :root_files Array of Hashes" do
      expect(subject[:root_files].first).to have_key(:path)
    end

    it "has a :checksum key value pair in a Hash of the :root_files Array of Hashes" do
      expect(subject[:root_files].first).to have_key(:checksum)
    end

    it "has a :specificity key value pair in a Hash of the :root_files Array of Hashes" do
      expect(subject[:root_files].first).to have_key(:specificity)
    end

    it "has a :cookbook_name key with a String value" do
      expect(subject).to have_key(:cookbook_name)
      expect(subject[:cookbook_name]).to be_a(String)
    end

    it "has a :metadata key with a Hashie::Mash value" do
      expect(subject).to have_key(:metadata)
      expect(subject[:metadata]).to be_a(Hashie::Mash)
    end

    it "has a :version key with a String value" do
      expect(subject).to have_key(:version)
      expect(subject[:version]).to be_a(String)
    end

    it "has a :name key with a String value" do
      expect(subject).to have_key(:name)
      expect(subject[:name]).to be_a(String)
    end

    it "has a value containing the cookbook name and version separated by a dash for :name" do
      name, version = subject[:name].split('-')

      expect(name).to eql(cookbook.cookbook_name)
      expect(version).to eql(cookbook.version)
    end

    it "has a :chef_type key with Cookbook::CHEF_TYPE as the value" do
      expect(subject).to have_key(:chef_type)
      expect(subject[:chef_type]).to eql(Ridley::Chef::Cookbook::CHEF_TYPE)
    end
  end

  describe "#to_json" do
    before(:each) do
      @json = subject.to_json
    end

    it "has a 'json_class' key with Cookbook::CHEF_JSON_CLASS  as the value" do
      expect(@json).to have_json_path('json_class')
      expect(parse_json(@json)['json_class']).to eql(Ridley::Chef::Cookbook::CHEF_JSON_CLASS)
    end

    it "has a 'frozen?' flag" do
      expect(@json).to have_json_path('frozen?')
    end
  end
end
