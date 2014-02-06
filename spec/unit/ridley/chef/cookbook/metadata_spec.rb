require 'spec_helper'

describe Ridley::Chef::Cookbook::Metadata do

  let(:metadata) do
    described_class.new
  end

  before(:each) do
     subject { metadata }
  end

  describe "#validate_choice_array" do
    it "should limit the types allowed in the choice array." do
      options = {
        :type => "string",
        :choice => [ "test1", "test2" ],
        :default => "test1"
      }
      lambda {
        subject.attribute("test_cookbook/test", options)
      }.should_not raise_error
  
      options = {
        :type => "boolean",
        :choice => [ true, false ],
        :default => true
      }
      lambda {
        subject.attribute("test_cookbook/test", options)
      }.should_not raise_error

      options = {
        :type => "numeric",
        :choice => [ 1337, 420 ],
        :default => 1337
      }
      lambda {
        subject.attribute("test_cookbook/test", options)
      }.should_not raise_error

      options = {
        :type => "numeric",
        :choice => [ true, "false" ],
        :default => false
      }
      lambda {
        subject.attribute("test_cookbook/test", options)
      }.should raise_error
    end
  end
end
