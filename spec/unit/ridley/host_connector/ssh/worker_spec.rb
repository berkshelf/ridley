require 'spec_helper'

describe Ridley::HostConnector::SSH::Worker do
  describe "ClassMethods" do
    let(:host) { 'reset.riotgames.com' }
    
    subject { described_class }

    describe "::new" do
      it { subject.new(host, ssh: {sudo: true}).sudo.should be_true }
      it { subject.new(host, ssh: {sudo: false}).sudo.should be_false }
      it { subject.new(host).sudo.should be_false }
    end
  end
end
