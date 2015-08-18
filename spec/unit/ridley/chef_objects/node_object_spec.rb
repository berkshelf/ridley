require 'spec_helper'

describe Ridley::NodeObject do
  let(:resource) { double('resource') }
  let(:instance) { described_class.new(resource) }
  subject { instance }

  describe "#chef_attributes" do
    subject { instance.chef_attributes }

    it "returns a Hashie::Mash" do
      expect(subject).to be_a(Hashie::Mash)
    end

    it "includes default attributes" do
      instance.default = default = { "default" => { "one" => "val", "two" => "val" } }
      expect(subject.to_hash).to include(default)
    end

    it "includes normal attributes" do
      instance.normal = normal = { "normal" => { "one" => "val", "two" => "val" } }
      expect(subject.to_hash).to include(normal)
    end

    it "includes override attributes" do
      instance.override = override = { "override" => { "one" => "val", "two" => "val" } }
      expect(subject.to_hash).to include(override)
    end

    it "includes automatic attributes" do
      instance.automatic = automatic = { "automatic" => { "one" => "val", "two" => "val" } }
      expect(subject.to_hash).to include(automatic)
    end

    it "overrides default attributes with normal attributes" do
      instance.default = default = { one: "old", two: "old" }
      instance.normal = normal = { one: "new" }
      expect(subject[:one]).to eql("new")
      expect(subject[:two]).to eql("old")
    end

    it "overrides normal attributes with override attributes" do
      instance.normal = normal = { one: "old", two: "old" }
      instance.override = override = { one: "new" }
      expect(subject[:one]).to eql("new")
      expect(subject[:two]).to eql("old")
    end

    it "overrides override attributes with automatic attributes" do
      instance.override = override = { one: "old", two: "old" }
      instance.automatic = automatic = { one: "new" }
      expect(subject[:one]).to eql("new")
      expect(subject[:two]).to eql("old")
    end
  end

  describe "#set_chef_attribute" do
    it "sets a normal node attribute at the nested path" do
       subject.set_chef_attribute('deep.nested.item', true)

       expect(subject.normal).to have_key("deep")
       expect(subject.normal["deep"]).to have_key("nested")
       expect(subject.normal["deep"]["nested"]).to have_key("item")
       expect(subject.normal["deep"]["nested"]["item"]).to be_truthy
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
        subject.set_chef_attribute('deep.nested.item', true)

        expect(subject.normal["deep"]["nested"]["item"]).to be_truthy
      end
    end
  end

  describe "#unset_chef_attribute" do
    context "when the attribute is set" do
      before do
        subject.normal = { foo: { bar: { baz: true } } }
      end

      it "unsets a normal node attribute at the nested path" do
        subject.unset_chef_attribute("foo.bar.baz")
        expect(subject.normal[:foo][:bar][:baz]).to be_nil
      end
    end

    ["string", true, :symbol, ["array"], Object.new].each do |nonattrs|
      context "when the attribute chain is partially set, interrupted by a #{nonattrs.class}" do
        let(:attributes) { { 'foo' => { 'bar' => nonattrs } } }
        before do
          subject.normal = attributes
        end

        it "leaves the attributes unchanged" do
          expect(subject.unset_chef_attribute("foo.bar.baz").to_hash).to eq(attributes)
        end
      end
    end

    context "when the attribute is not set" do
      let(:attributes) { { 'bizz' => { 'bar' => { 'baz' => true } } } }
      before do
        subject.normal = attributes
      end

      it "leaves the attributes unchanged" do
        expect(subject.unset_chef_attribute("foo.bar.baz").to_hash).to eq(attributes)
      end
    end
  end

  describe "#cloud?" do
    it "returns true if the cloud automatic attribute is set" do
      subject.automatic = {
        "cloud" => Hash.new
      }

      expect(subject.cloud?).to be_truthy
    end

    it "returns false if the cloud automatic attribute is not set" do
      subject.automatic.delete(:cloud)

      expect(subject.cloud?).to be_falsey
    end
  end

  describe "#eucalyptus?" do
    it "returns true if the node is a cloud node using the eucalyptus provider" do
      subject.automatic = {
        "cloud" => {
          "provider" => "eucalyptus"
        }
      }

      expect(subject.eucalyptus?).to be_truthy
    end

    it "returns false if the node is not a cloud node" do
      subject.automatic.delete(:cloud)

      expect(subject.eucalyptus?).to be_falsey
    end

    it "returns false if the node is a cloud node but not using the eucalyptus provider" do
      subject.automatic = {
        "cloud" => {
          "provider" => "ec2"
        }
      }

      expect(subject.eucalyptus?).to be_falsey
    end
  end

  describe "#ec2?" do
    it "returns true if the node is a cloud node using the ec2 provider" do
      subject.automatic = {
        "cloud" => {
          "provider" => "ec2"
        }
      }

      expect(subject.ec2?).to be_truthy
    end

    it "returns false if the node is not a cloud node" do
      subject.automatic.delete(:cloud)

      expect(subject.ec2?).to be_falsey
    end

    it "returns false if the node is a cloud node but not using the ec2 provider" do
      subject.automatic = {
        "cloud" => {
          "provider" => "rackspace"
        }
      }

      expect(subject.ec2?).to be_falsey
    end
  end

  describe "#rackspace?" do
    it "returns true if the node is a cloud node using the rackspace provider" do
      subject.automatic = {
        "cloud" => {
          "provider" => "rackspace"
        }
      }

      expect(subject.rackspace?).to be_truthy
    end

    it "returns false if the node is not a cloud node" do
      subject.automatic.delete(:cloud)

      expect(subject.rackspace?).to be_falsey
    end

    it "returns false if the node is a cloud node but not using the rackspace provider" do
      subject.automatic = {
        "cloud" => {
          "provider" => "ec2"
        }
      }

      expect(subject.rackspace?).to be_falsey
    end
  end

  describe "#cloud_provider" do
    it "returns the cloud provider if the node is a cloud node" do
      subject.automatic = {
        "cloud" => {
          "provider" => "ec2"
        }
      }

      expect(subject.cloud_provider).to eql("ec2")
    end

    it "returns nil if the node is not a cloud node" do
      subject.automatic.delete(:cloud)

      expect(subject.cloud_provider).to be_nil
    end
  end

  describe "#public_ipv4" do
    it "returns the public ipv4 address if the node is a cloud node" do
      subject.automatic = {
        "cloud" => {
          "provider" => "ec2",
          "public_ipv4" => "10.0.0.1"
        }
      }

      expect(subject.public_ipv4).to eql("10.0.0.1")
    end

    it "returns the ipaddress if the node is not a cloud node" do
      subject.automatic = {
        "ipaddress" => "192.168.1.1"
      }
      subject.automatic.delete(:cloud)

      expect(subject.public_ipv4).to eql("192.168.1.1")
    end
  end

  describe "#public_hostname" do
    it "returns the public hostname if the node is a cloud node" do
      subject.automatic = {
        "cloud" => {
          "public_hostname" => "reset.cloud.riotgames.com"
        }
      }

      expect(subject.public_hostname).to eql("reset.cloud.riotgames.com")
    end

    it "returns the FQDN if the node is not a cloud node" do
      subject.automatic = {
        "fqdn" => "reset.internal.riotgames.com"
      }
      subject.automatic.delete(:cloud)

      expect(subject.public_hostname).to eql("reset.internal.riotgames.com")
    end
  end

  describe "#merge_data" do
    before(:each) { subject.name = "reset.riotgames.com" }

    it "appends items to the run_list" do
      subject.merge_data(run_list: ["cook::one", "cook::two"])

      expect(subject.run_list).to match_array(["cook::one", "cook::two"])
    end

    it "ensures the run_list is unique if identical items are given" do
      subject.run_list = [ "cook::one" ]
      subject.merge_data(run_list: ["cook::one", "cook::two"])

      expect(subject.run_list).to match_array(["cook::one", "cook::two"])
    end

    it "deep merges attributes into the normal attributes" do
      subject.normal = {
        one: {
          two: {
            four: :deep
          }
        }
      }
      subject.merge_data(attributes: {
        one: {
          two: {
            three: :deep
          }
        }
      })

      expect(subject.normal[:one][:two]).to have_key(:four)
      expect(subject.normal[:one][:two][:four]).to eql(:deep)
      expect(subject.normal[:one][:two]).to have_key(:three)
      expect(subject.normal[:one][:two][:three]).to eql(:deep)
    end
  end
end
