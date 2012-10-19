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

  describe "#set_attribute" do
    it "returns a HashWithIndifferentAccess" do
      subject.set_attribute('deep.nested.item', true).should be_a(HashWithIndifferentAccess)
    end

    it "sets an normal node attribute at the nested path" do
       subject.set_attribute('deep.nested.item', true)

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
        subject.set_attribute('deep.nested.item', true)
        
        subject.normal["deep"]["nested"]["item"].should be_true
      end
    end
  end

  describe "#eucalyptus?" do
    it "returns true if the eucalyptus automatic attribute is set" do
      subject.automatic = {
        "eucalyptus" => Hash.new
      }

      subject.eucalyptus?.should be_true
    end

    it "returns false if the eucalyptus automatic attribute is not set" do
      subject.automatic.delete(:eucalyptus)

      subject.eucalyptus?.should be_false
    end
  end

  describe "#ec2?" do
    it "returns true if the ec2 automatic attribute is set" do
      subject.automatic = {
        "ec2" => Hash.new
      }

      subject.ec2?.should be_true
    end

    it "returns false if the ec2 automatic attribute is not set" do
      subject.automatic.delete(:ec2)

      subject.ec2?.should be_false
    end
  end
end
