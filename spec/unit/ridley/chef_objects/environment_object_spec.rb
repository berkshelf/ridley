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

    shared_examples_for "attribute deleter" do
      let(:precedence) { raise "You must provide the precedence level (let(:precedence) { \"default\" } in the shared example context" }
      let(:delete_attribute) { subject.send(:"delete_#{precedence}_attribute", attribute_key) }
      let(:attribute_key) { "hello.world" }

      before do
        subject.send(:"set_#{precedence}_attribute", "hello.world", true)
      end

      it "removes the attribute" do
        delete_attribute
        expect(subject.send(:"#{precedence}_attributes")[:hello][:world]).to be_nil
      end

      context "when the attribute does not exist" do
        let(:attribute_key) { "not.existing" }

        it "does not delete anything" do
          delete_attribute
          expect(subject.send(:"#{precedence}_attributes")[:hello][:world]).to be_true
        end
      end

      context "when an internal hash is nil" do
        let(:attribute_key) { "never.not.existing" }

        before do
          subject.send(:"#{precedence}_attributes=", Hash.new)
        end

        it "does not delete anything" do
          delete_attribute
          expect(subject.send(:"#{precedence}_attributes")).to be_empty
        end
      end
    end

    describe "#delete_default_attribute" do
      it_behaves_like "attribute deleter" do
        let(:precedence) { "default" }
      end
    end

    describe "#delete_override_attribute" do
      it_behaves_like "attribute deleter" do
        let(:precedence) { "override" }
      end
    end
  end
end
