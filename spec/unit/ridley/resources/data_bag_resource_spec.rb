require 'spec_helper'

describe Ridley::DataBagResource do
  let(:secret) { "supersecretkey" }
  let(:instance) { described_class.new(double, secret) }

  describe "#item_resource" do
    subject { instance.item_resource }

    it "returns a DataBagItemResource" do
      subject.should be_a(Ridley::DataBagItemResource)
    end

    its(:encrypted_data_bag_secret) { should eql(secret) }
  end

  describe "#find" do
    pending
  end
end
