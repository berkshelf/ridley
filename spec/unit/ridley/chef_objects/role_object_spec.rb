require 'spec_helper'

describe Ridley::RoleObject do
  subject { described_class.new(double('registry')) }

  describe "#set_override_attribute" do
    it "sets an override node attribute at the nested path" do
       subject.set_override_attribute('deep.nested.item', true)

       expect(subject.override_attributes).to have_key("deep")
       expect(subject.override_attributes["deep"]).to have_key("nested")
       expect(subject.override_attributes["deep"]["nested"]).to have_key("item")
       expect(subject.override_attributes["deep"]["nested"]["item"]).to be_truthy
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

        expect(subject.override_attributes["deep"]["nested"]["item"]).to be_truthy
      end
    end
  end

  describe "#set_default_attribute" do
    it "sets an override node attribute at the nested path" do
       subject.set_default_attribute('deep.nested.item', true)

       expect(subject.default_attributes).to have_key("deep")
       expect(subject.default_attributes["deep"]).to have_key("nested")
       expect(subject.default_attributes["deep"]["nested"]).to have_key("item")
       expect(subject.default_attributes["deep"]["nested"]["item"]).to be_truthy
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

        expect(subject.default_attributes["deep"]["nested"]["item"]).to be_truthy
      end
    end
  end
end
