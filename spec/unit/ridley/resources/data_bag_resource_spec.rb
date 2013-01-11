require 'spec_helper'

describe Ridley::DataBagResource do
  it_behaves_like "a Ridley Resource", Ridley::DataBagResource

  let(:connection) { double('connection') }

  describe "ClassMethods" do
    subject { Ridley::DataBagResource }

    describe "::create_item" do
      pending
    end
  end
end
