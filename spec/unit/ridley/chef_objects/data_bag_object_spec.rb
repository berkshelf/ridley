require 'spec_helper'

describe Ridley::DataBagObject do
  let(:item_resource) { double('item-resource') }
  let(:resource) { double('db-resource', item_resource: item_resource) }
  subject { described_class.new(resource) }

  describe '#item' do
    subject { super().item }
    it { is_expected.to be_a(Ridley::DataBagObject::DataBagItemProxy) }
  end
end
