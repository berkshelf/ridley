require 'spec_helper'

describe Ridley::Client do
  it_behaves_like "a Ridley Resource", Ridley::Client

  let(:connection) { double('connection') }

  before(:each) do
    Ridley::Connection.active = connection
  end

  describe "ClassMethods" do
    subject { Ridley::Client }

    describe "::regenerate_key" do
      let(:client) { double('client', name: "ridley-test") }

      it "finds the given client and regenerates it's key" do
        client.should_receive(:regenerate_key)
        subject.should_receive(:find!).with("ridley-test").and_return(client)
        
        subject.regenerate_key("ridley-test")
      end

      it "returns the updated client" do
        client.should_receive(:regenerate_key)
        subject.should_receive(:find!).with("ridley-test").and_return(client)

        subject.regenerate_key("ridley-test").should eql(client)
      end
    end
  end

  subject do
    Ridley::Client.new(name: "ridley-test", admin: false)
  end

  describe "#regenerate_key" do
    it "returns true if successful" do
      subject.should_receive(:save).and_return(true)

      subject.regenerate_key.should be_true
    end

    it "returns false if not successful" do
      subject.should_receive(:save).and_return(false)

      subject.regenerate_key.should be_false
    end
  end
end
