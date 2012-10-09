require 'spec_helper'

describe Ridley::Node do
  it_behaves_like "a Ridley Resource", Ridley::Node

  let(:connection) { double("connection") }

  subject { Ridley::Node.new(connection) }

  describe "#override=" do
    context "given a Hash" do
      it "returns a HashWithIndifferentAccess" do
        subject.override = {
          "key" => "value"
        }

        subject.override.should be_a(HashWithIndifferentAccess)
      end
    end
  end

  describe "#automatic=" do
    context "given a Hash" do
      it "returns a HashWithIndifferentAccess" do
        subject.automatic = {
          "key" => "value"
        }

        subject.automatic.should be_a(HashWithIndifferentAccess)
      end
    end
  end

  describe "#normal=" do
    context "given a Hash" do
      it "returns a HashWithIndifferentAccess" do
        subject.normal = {
          "key" => "value"
        }

        subject.normal.should be_a(HashWithIndifferentAccess)
      end
    end
  end

  describe "#default=" do
    context "given a Hash" do
      it "returns a HashWithIndifferentAccess" do
        subject.default = {
          "key" => "value"
        }

        subject.default.should be_a(HashWithIndifferentAccess)
      end
    end
  end

  describe "#set_override_attribute" do
    it "returns a HashWithIndifferentAccess" do
      subject.set_override_attribute('deep.nested.item', true).should be_a(HashWithIndifferentAccess)
    end

    it "sets an override node attribute at the nested path" do
       subject.set_override_attribute('deep.nested.item', true)

       subject.override.should have_key("deep")
       subject.override["deep"].should have_key("nested")
       subject.override["deep"]["nested"].should have_key("item")
       subject.override["deep"]["nested"]["item"].should be_true
    end

    context "when the override attribute is already set" do
      it "test" do
        subject.override = {
          deep: {
            nested: {
              item: false
            }
          }
        }
        subject.set_override_attribute('deep.nested.item', true)
        
        subject.override["deep"]["nested"]["item"].should be_true
      end
    end
  end

  describe "#set_normal_attribute" do
    it "returns a HashWithIndifferentAccess" do
      subject.set_normal_attribute('deep.nested.item', true).should be_a(HashWithIndifferentAccess)
    end

    it "sets an normal node attribute at the nested path" do
       subject.set_normal_attribute('deep.nested.item', true)

       subject.normal.should have_key("deep")
       subject.normal["deep"].should have_key("nested")
       subject.normal["deep"]["nested"].should have_key("item")
       subject.normal["deep"]["nested"]["item"].should be_true
    end

    context "when the normal attribute is already set" do
      it "test" do
        subject.normal = {
          deep: {
            nested: {
              item: false
            }
          }
        }
        subject.set_normal_attribute('deep.nested.item', true)
        
        subject.normal["deep"]["nested"]["item"].should be_true
      end
    end
  end

  describe "#set_default_attribute" do
    it "returns a HashWithIndifferentAccess" do
      subject.set_default_attribute('deep.nested.item', true).should be_a(HashWithIndifferentAccess)
    end

    it "sets an default node attribute at the nested path" do
       subject.set_default_attribute('deep.nested.item', true)

       subject.default.should have_key("deep")
       subject.default["deep"].should have_key("nested")
       subject.default["deep"]["nested"].should have_key("item")
       subject.default["deep"]["nested"]["item"].should be_true
    end

    context "when the default attribute is already set" do
      it "test" do
        subject.default = {
          deep: {
            nested: {
              item: false
            }
          }
        }
        subject.set_default_attribute('deep.nested.item', true)
        
        subject.default["deep"]["nested"]["item"].should be_true
      end
    end
  end
end
