require 'spec_helper'

describe Ridley::DataBagResource do
  let(:secret) { "supersecretkey" }
  let(:instance) { described_class.new(double, secret) }

  describe "#item_resource" do
    subject { instance.item_resource }

    it "returns a DataBagItemResource" do
      expect(subject).to be_a(Ridley::DataBagItemResource)
    end

    describe '#encrypted_data_bag_secret' do
      subject { super().encrypted_data_bag_secret }
      it { is_expected.to eql(secret) }
    end
  end

  describe "#find" do
    skip
  end
end
