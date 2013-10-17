require 'spec_helper'

describe Ridley::EnvironmentObject do
  subject { described_class.new(double('registry')) }

  describe "#set_override_attribute" do
    it "sets an override node attribute at the nested path" do
       subject.set_override_attribute('deep.nested.item', true)

       subject.override_attributes.should have_key("deep")
       subject.override_attributes["deep"].should have_key("nested")
       subject.override_attributes["deep"]["nested"].should have_key("item")
       subject.override_attributes["deep"]["nested"]["item"].should be_true
    end

    context "when the override attribute is already set" do
      it "test" do
        subject.override_attributes = {
          deep: {
            nested: {
              item: false
            }
          }
        }
        subject.set_override_attribute('deep.nested.item', true)

        subject.override_attributes["deep"]["nested"]["item"].should be_true
      end
    end
  end

  describe "#set_default_attribute" do
    it "sets an override node attribute at the nested path" do
       subject.set_default_attribute('deep.nested.item', true)

       subject.default_attributes.should have_key("deep")
       subject.default_attributes["deep"].should have_key("nested")
       subject.default_attributes["deep"]["nested"].should have_key("item")
       subject.default_attributes["deep"]["nested"]["item"].should be_true
    end

    context "when the override attribute is already set" do
      it "test" do
        subject.default_attributes = {
          deep: {
            nested: {
              item: false
            }
          }
        }
        subject.set_default_attribute('deep.nested.item', true)

        subject.default_attributes["deep"]["nested"]["item"].should be_true
      end
    end

    describe "#delete_default_attribute" do
      let(:delete_default_attribute) { subject.delete_default_attribute(attribute_key) }
      let(:attribute_key) { "hello.world" }

      before do
        subject.set_default_attribute(attribute_key, true)
      end

      it "removes the default attribute" do
        delete_default_attribute
        expect(subject.default_attributes[:hello][:world]).to be_nil
      end

      context "when the attribute does not exist" do
        let(:delete_default_attribute) { subject.delete_default_attribute("not.existing") }

        it "does not delete anything" do
          delete_default_attribute
          expect(subject.default_attributes[:hello][:world]).to be_true
        end
      end
    end

    describe "#delete_override_attribute" do
      let(:delete_override_attribute) { subject.delete_override_attribute(attribute_key) }
      let(:attribute_key) { "hello.world" }

      before do
        subject.set_override_attribute(attribute_key, true)
      end

      it "removes the override attribute" do
        delete_override_attribute
        expect(subject.override_attributes[:hello][:world]).to be_nil
      end

      context "when the attribute does not exist" do
        let(:delete_override_attribute) { subject.delete_override_attribute("not.existing") }

        it "does not delete anything" do
          delete_override_attribute
          expect(subject.override_attributes[:hello][:world]).to be_true
        end
      end
    end
  end
end
