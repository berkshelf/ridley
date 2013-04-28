require 'spec_helper'

describe Ridley::Chef::Chefignore do
  describe "ClassMethods" do
    subject { described_class }

    describe "::find_relative_to" do
      let(:path) { tmp_path.join('chefignore-test') }
      before(:each) { FileUtils.mkdir_p(path) }

      it "finds a chefignore file in a 'cookbooks' directory relative to the given path" do
        FileUtils.touch(path.join('chefignore'))
        subject.find_relative_to(path)
      end

      it "finds a chefignore file relative to the given path" do
        FileUtils.mkdir_p(path.join('cookbooks'))
        FileUtils.touch(path.join('cookbooks', 'chefignore'))
        subject.find_relative_to(path)
      end
    end
  end

  subject { described_class.new(File.join(fixtures_path)) }

  it "loads the globs in the chefignore file" do
    subject.ignores.should =~ %w[recipes/ignoreme.rb ignored]
  end

  it "removes items from an array that match the ignores" do
    file_list = %w[ recipes/ignoreme.rb recipes/dontignoreme.rb ]
    subject.remove_ignores_from(file_list).should == %w[recipes/dontignoreme.rb]
  end

  it "determines if a file is ignored" do
    subject.ignored?('ignored').should be_true
    subject.ignored?('recipes/ignoreme.rb').should be_true
    subject.ignored?('recipes/dontignoreme.rb').should be_false
  end
end
