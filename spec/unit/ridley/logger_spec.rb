require 'spec_helper'

describe Ridley::Logging::Logger do
  subject { described_class.new("/dev/null") }
  let(:message) { "my message" }
  let(:filtered_param) { "message" }

  describe "::initialize" do
    it "defaults to info" do
      expect(subject.level).to eq(Logger::WARN)
    end
  end

  describe "#info" do

    before do
      subject.level = Logger::INFO
      subject.filter_param filtered_param
    end

    it "supports filtering" do
      expect(subject).to receive(:filter).with("my message").and_return("my FILTERED")
      subject.info message
    end
  end

  describe "#filter_params" do
    it "returns an array" do
      expect(subject.filter_params).to be_a(Array)
    end
  end

  describe "#filter_param" do
    let(:param) { "hello" }

    before do
      subject.clear_filter_params
    end

    it "adds an element to the array" do
      subject.filter_param(param)
      expect(subject.filter_params).to include(param)
      expect(subject.filter_params.size).to eq(1)
    end

    context "when the element is already in the array" do

      before do
        subject.filter_param(param)
      end
      it "does not duplicate the element" do
        subject.filter_param(param)
        expect(subject.filter_params.size).to eq(1)
      end
    end
  end

  describe "#filter" do

    before do
      subject.filter_param(filtered_param)
    end

    it "replaces entries in filter_params" do
      expect(subject.filter(message)).to eq("my FILTERED")
    end

    context "when there are multiple filter_params" do
      before do
        subject.filter_param("fake param")
        subject.filter_param(filtered_param) 
      end

      it "replaces only matching filter_params" do
        expect(subject.filter(message)).to eq("my FILTERED")
      end
    end
  end
end
