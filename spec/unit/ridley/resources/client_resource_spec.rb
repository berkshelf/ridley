require 'spec_helper'

describe Ridley::ClientResource do
  it_behaves_like "a Ridley Resource", Ridley::ClientResource

  let(:connection) { double('connection') }

  describe "ClassMethods" do
    subject { Ridley::ClientResource }

    describe "::regenerate_key" do
      let(:client) { double('client', name: "ridley-test") }

      it "finds the given client and regenerates it's key" do
        client.should_receive(:regenerate_key)
        subject.should_receive(:find!).with(connection, "ridley-test").and_return(client)
        
        subject.regenerate_key(connection, "ridley-test")
      end

      it "returns the updated client" do
        client.should_receive(:regenerate_key)
        subject.should_receive(:find!).with(connection, "ridley-test").and_return(client)

        subject.regenerate_key(connection, "ridley-test").should eql(client)
      end
    end
  end

  subject do
    Ridley::ClientResource.new(connection, name: "ridley-test", admin: false)
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
