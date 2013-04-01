require 'spec_helper'

describe Ridley::HostConnector::ResponseSet do
  describe "ClassMethods" do
    subject { described_class }

    describe "::merge!" do
      let(:target) { Ridley::HostConnector::ResponseSet.new }
      let(:other) { Ridley::HostConnector::ResponseSet.new }

      before(:each) do
        other.add_response(Ridley::HostConnector::Response.new('host.local'))
      end

      it "returns the mutated target" do
        result = subject.merge!(target, other)

        result.should eql(target)
        result.should have(1).item
      end
    end
  end

  subject { described_class.new }

  describe "#add_response" do
    it "accepts an array of responses" do
      responses = [
        Ridley::HostConnector::Response.new("one.riotgames.com"),
        Ridley::HostConnector::Response.new("two.riotgames.com")
      ]
      subject.add_response(responses)

      subject.responses.should have(2).items
    end

    it "accepts a single response" do
      response = Ridley::HostConnector::Response.new("one.riotgames.com")
      subject.add_response(response)

      subject.responses.should have(1).item
    end
  end

  describe "#responses" do
    it "returns an array of Ridley::HostConnector::Response objects including both failures and successes" do
      responses = [
        double('success', error?: false),
        double('failure', error?: true)
      ]
      subject.add_response(responses)

      subject.responses.should have(2).items
    end
  end

  describe "#successes" do
    it "returns an array of Ridley::HostConnector::Response objects only including the successes" do
      responses = [
        double('success', error?: false),
        double('failure', error?: true)
      ]
      subject.add_response(responses)

      subject.successes.should have(1).item
    end
  end

  describe "#failures" do
    it "returns an array of Ridley::HostConnector::Response objects only including the failures" do
      responses = [
        double('success', error?: false),
        double('failure', error?: true)
      ]
      subject.add_response(responses)

      subject.failures.should have(1).item
    end
  end

  describe "#merge" do
    let(:target) { Ridley::HostConnector::ResponseSet.new }
    let(:other) { Ridley::HostConnector::ResponseSet.new }

    before(:each) do
      other.add_response(Ridley::HostConnector::Response.new('host.local'))
    end

    it "returns a new Ridley::HostConnector::ResponseSet object" do
      result = target.merge(other)

      result.should have(1).item
      target.should have(0).items
    end
  end

  describe "#merge!" do
    let(:target) { Ridley::HostConnector::ResponseSet.new }
    let(:other) { Ridley::HostConnector::ResponseSet.new }

    before(:each) do
      other.add_response(Ridley::HostConnector::Response.new('host.local'))
    end

    it "returns the mutated target" do
      result = target.merge!(other)

      result.should have(1).item
      target.should have(1).item
    end
  end
end
