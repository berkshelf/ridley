require 'spec_helper'

describe Ridley::Chef::Cookbook::SyntaxCheck do

  let(:cookbook_dir) { fixtures_path.join('example_cookbook')}
  let(:chefignore) { Ridley::Chef::Chefignore.new(cookbook_dir) }

  let(:syntax_check) do
    described_class.new(fixtures_path, chefignore)
  end

  subject { syntax_check }

  before(:each) do
    subject.stub(:chefignore) { chefignore }
  end

  describe "#ruby_files" do
    it "lists the rb files in a cookbook" do
      expect(subject.ruby_files).to include(cookbook_dir.join("libraries/my_lib.rb").to_s)
    end

    it "does not list the rb files in a cookbook that are ignored" do
      expect(subject.ruby_files).not_to include(cookbook_dir.join("ignores/magic.rb").to_s)
    end
  end

  describe "#untested_ruby_files" do
    it "filters out validated rb files" do
      valid_ruby_file = cookbook_dir.join("libraries/my_lib.rb").to_s
      subject.validated(valid_ruby_file)
      expect(subject.untested_ruby_files).not_to include(valid_ruby_file)
    end
  end

  describe "#template_files" do
    it "lists the erb files in a cookbook" do
      expect(subject.template_files).to include(cookbook_dir.join("templates/default/temp.txt.erb").to_s)
    end

    it "does not list the erb files in a cookbook that are ignored" do
      expect(subject.template_files).not_to include(cookbook_dir.join("ignores/magic.erb").to_s)
    end
  end

  describe "#untested_template_files" do
    it "filters out validated erb files" do
      valid_template_file = cookbook_dir.join("templates/default/temp.txt.erb").to_s
      subject.validated(valid_template_file)
      expect(subject.untested_template_files).not_to include(valid_template_file)
    end
  end

  describe "#validated?" do
    it "checks if a file has already been validated" do
      valid_template_file = cookbook_dir.join("templates/default/temp.txt.erb").to_s
      subject.validated(valid_template_file)
      expect(subject.validated?(valid_template_file)).to be_true
    end
  end

  describe "#validated" do
    let(:validated_files) { double('validated_files') }

    before(:each) do
      subject.stub(:validated_files) { validated_files }
    end

    it "records a file as validated" do
      template_file = cookbook_dir.join("templates/default/temp.txt.erb").to_s
      file_checksum = Ridley::Chef::Digester.checksum_for_file(template_file)

      expect(validated_files).to receive(:add).with(file_checksum)
      expect(subject.validated(template_file)).to be_nil
    end
  end

  describe "#validate_ruby_files" do
    it "asks #untested_ruby_files for a list of files and calls #validate_ruby_file on each" do
      subject.stub(:validate_ruby_file).with(anything()).exactly(9).times { true }
      expect(subject.validate_ruby_files).to be_true
    end

    it "marks the successfully validated ruby files" do
      subject.stub(:validated).with(anything()).exactly(9).times
      expect(subject.validate_ruby_files).to be_true
    end

    it "returns false if any ruby file fails to validate" do
      subject.stub(:validate_ruby_file).with(/\.rb$/) { false }
      expect(subject.validate_ruby_files).to be_false
    end
  end

  describe "#validate_templates" do
    it "asks #untested_template_files for a list of erb files and calls #validate_template on each" do
      subject.stub(:validate_template).with(anything()).exactly(9).times { true }
      expect(subject.validate_templates).to be_true
    end

    it "marks the successfully validated erb files" do
      subject.stub(:validated).with(anything()).exactly(9).times
      expect(subject.validate_templates).to be_true
    end

    it "returns false if any erb file fails to validate" do
      subject.stub(:validate_template).with(/\.erb$/) { false }
      expect(subject.validate_templates).to be_false
    end
  end

  describe "#validate_template" do
    it "asks #shell_out to check the files syntax"
  end

  describe "#validate_ruby_file" do
    it "asks #shell_out to check the files syntax"
  end

  describe "without a chefignore" do
    let(:chefignore) { nil }

    it "the file listing still works" do
      expect(subject.ruby_files).to include(cookbook_dir.join("libraries/my_lib.rb").to_s)
    end
  end
end
