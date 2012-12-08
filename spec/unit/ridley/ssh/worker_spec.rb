require 'spec_helper'

describe Ridley::SSH::Worker do
  describe "ClassMethods" do
    subject { described_class }

    describe "::new" do
      it { subject.new(sudo: true).sudo.should be_true }
      it { subject.new(sudo: false).sudo.should be_false }
      it { subject.new().sudo.should be_false }
    end
  end
end
