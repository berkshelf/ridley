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
      subject.ruby_files.should include(cookbook_dir.join("libraries/my_lib.rb").to_s)
    end
    it "does not list the rb files in a cookbook that are ignored" do
      subject.ruby_files.should_not include(cookbook_dir.join("ignores/magic.rb").to_s)
    end
  end

  describe "#untested_ruby_files" do
    it "filters out validated rb files" do
      valid_ruby_file = cookbook_dir.join("libraries/my_lib.rb").to_s
      subject.validated(valid_ruby_file)
      subject.untested_ruby_files.should_not include(valid_ruby_file)
    end
  end

  describe "#template_files" do
    it "lists the erb files in a cookbook" do
      subject.template_files.should include(cookbook_dir.join("templates/default/temp.txt.erb").to_s)
    end
    it "does not list the erb files in a cookbook that are ignored" do
      subject.template_files.should_not include(cookbook_dir.join("ignores/magic.erb").to_s)
    end
  end

  describe "#untested_template_files" do
    it "filters out validated erb files" do
      valid_template_file = cookbook_dir.join("templates/default/temp.txt.erb").to_s
      subject.validated(valid_template_file)
      subject.untested_template_files.should_not include(valid_template_file)
    end
  end

  describe "#validated?" do
    it "checks if a file has already been validated" do
      valid_template_file = cookbook_dir.join("templates/default/temp.txt.erb").to_s
      subject.validated(valid_template_file)
      subject.validated?(valid_template_file).should be_true
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

      validated_files.should_receive(:add).with(file_checksum)

      subject.validated(template_file)
    end
  end

  describe "#validate_ruby_files" do
    it "asks #untested_ruby_files for a list of files and calls #validate_ruby_file on each"
    it "marks the successfully validated ruby files"
    it "returns false if any ruby file fails to validate"
  end

  describe "#validate_templates" do
    it "asks #untested_template_files for a list of erb files and calls #validate_template on each"
    it "marks the successfully validated erb files"
    it "returns false if any erb file fails to validate"
  end

  describe "#validate_template" do
    it "asks #shell_out to check the files syntax"
  end

  describe "#validate_ruby_file" do
    it "asks #shell_out to check the files syntax"
  end

  #describe "#validate" do
  #  let(:syntax_checker) { double('syntax_checker') }
  #
  #  before(:each) do
  #    subject.stub(:syntax_checker) { syntax_checker }
  #  end
  #
  #  it "asks the syntax_checker to validate the ruby and template files of the cookbook" do
  #    syntax_checker.should_receive(:validate_ruby_files).and_return(true)
  #    syntax_checker.should_receive(:validate_templates).and_return(true)
  #
  #    subject.validate
  #  end
  #
  #  it "raises CookbookSyntaxError if the cookbook contains invalid ruby files" do
  #    syntax_checker.should_receive(:validate_ruby_files).and_return(false)
  #
  #    lambda {
  #      subject.validate
  #    }.should raise_error(Ridley::Errors::CookbookSyntaxError)
  #  end
  #
  #  it "raises CookbookSyntaxError if the cookbook contains invalid template files" do
  #    syntax_checker.should_receive(:validate_ruby_files).and_return(true)
  #    syntax_checker.should_receive(:validate_templates).and_return(false)
  #
  #    lambda {
  #      subject.validate
  #    }.should raise_error(Ridley::Errors::CookbookSyntaxError)
  #  end
  #end
end
