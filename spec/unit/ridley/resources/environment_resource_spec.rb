require 'spec_helper'

describe Ridley::EnvironmentResource do
  subject { described_class.new(double('registry')) }

  describe "#delete_all" do
    let(:default_env) { double(name: "_default") }
    let(:destroy_env) { double(name: "destroy_me") }

    before do
      subject.stub(all: [ default_env, destroy_env ])
    end

    it "does not destroy the '_default' environment" do
      subject.stub(future: double('future', value: nil))
      subject.should_not_receive(:future).with(:delete, default_env)

      subject.delete_all
    end
  end
end
