require 'spec_helper'

describe Ridley do
  let(:config) { double("config") }

  describe "ClassMethods" do
    subject { Ridley }

    describe "::new" do
      it "creates a new Ridley::Connection" do
        client = double('client')
        Ridley::Client.should_receive(:new).with(config).and_return(client)

        subject.new(config).should eql(client)
      end
    end
  end
end
