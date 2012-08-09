require 'spec_helper'

describe Ridley::Connection do
  let(:server_url) { "https://api.opscode.com/organizations/vialstudios/" }
  let(:client_name) { "reset" }
  let(:client_key) { "/Users/reset/.chef/reset.pem" }

  describe "ClassMethods" do
    subject { Ridley::Connection }

    before(:each) do
      @original_conn = subject.active
    end

    after(:each) do
      subject.active = @original_conn
    end

    describe "::start" do
      it "creates a new instance of Ridley::Connection and sets it to the active connection" do
        subject.start(server_url, client_name, client_key) do
          Ridley::Connection.active.should_not be_nil
        end
      end

      it "sets the Ridley::Connection.active to the original after the block ends" do
        subject.active = :fake
        subject.start(server_url, client_name, client_key) do; end

        subject.active.should eql(:fake)
      end

      it "raises a Ridley::Errors::InternalError if no block is given" do
        lambda {
          subject.start(server_url, client_name, client_key)
        }.should raise_error(Ridley::Errors::InternalError)
      end
    end
  end

  subject do
    Ridley::Connection.new(server_url, client_name, client_key)
  end

  describe "#start" do
    before(:each) do
      @original_conn = Ridley::Connection.active
    end

    after(:each) do
      Ridley::Connection.active = @original_conn
    end

    it "sets the Ridley::Connection.active to self" do
      subject.start do
        Ridley::Connection.active.should eql(subject)
      end
    end

    it "sets the Ridley::Connection.active to the original after the block ends" do
      subject.class.active = :fake
      subject.start do; end

      Ridley::Connection.active.should eql(:fake)
    end

    it "raises a Ridley::Errors::InternalError if no block is given" do
      lambda {
        subject.start
      }.should raise_error(Ridley::Errors::InternalError)
    end

    describe "#environment" do
      it "it returns the Ridley::Environment class" do
        subject.start do
          environment.should eql(Ridley::Environment)
        end
      end
    end
  end
end
