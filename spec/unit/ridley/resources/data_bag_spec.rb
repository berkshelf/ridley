require 'spec_helper'

describe Ridley::DataBag do
  it_behaves_like "a Ridley Resource", Ridley::DataBag

  let(:connection) { double('connection') }

  describe "ClassMethods" do
    subject { Ridley::DataBag }

    describe "::create_item" do
      pending
    end
  end
end
