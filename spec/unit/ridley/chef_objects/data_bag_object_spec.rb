require 'spec_helper'

describe Ridley::DataBagObject do
  let(:item_resource) { double('item-resource') }
  let(:resource) { double('db-resource', item_resource: item_resource) }
  subject { described_class.new(resource) }

  its(:item) { should be_a(Ridley::DataBagObject::DataBagItemProxy) }
end
