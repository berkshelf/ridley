require 'spec_helper'

describe Ridley do
  let(:config) { double("config") }

  describe "ClassMethods" do
    subject { Ridley }

    describe "::start" do
      it "delegates to Ridley::Connection.start" do
        Ridley::Connection.should_receive(:start).with(config)

        subject.start(config) do; end
      end
    end

    describe "::connection" do
      it "creates a new Ridley::Connection" do
        conn = double('conn')
        Ridley::Connection.should_receive(:new).with(config).and_return(conn)

        subject.connection(config).should eql(conn)
      end
    end

    describe "::log" do
      it "returns the Ridley::Log singleton" do
        subject.log.should eql(Ridley::Log)
      end
    end
  end
end
