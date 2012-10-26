require 'spec_helper'

describe Ridley do
  let(:config) { double("config") }

  describe "ClassMethods" do
    subject { Ridley }

    describe "::sync" do
      it "delegates to Ridley::Connection.sync" do
        Ridley::Connection.should_receive(:sync).with(config)

        subject.sync(config) do; end
      end
    end

    describe "::connection" do
      it "creates a new Ridley::Connection" do
        conn = double('conn')
        Ridley::Connection.should_receive(:new).with(config).and_return(conn)

        subject.connection(config).should eql(conn)
      end
    end
  end
end
