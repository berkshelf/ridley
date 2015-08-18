describe Ridley::ChefObject do
  let(:resource) { double('chef-resource') }

  describe "ClassMethods" do
    subject { Class.new(described_class) }

    describe "::new" do
      it "mass assigns the given attributes" do
        new_attrs = {
          name: "a name"
        }

        expect_any_instance_of(subject).to receive(:mass_assign).with(new_attrs)
        subject.new(resource, new_attrs)
      end
    end

    describe "::set_chef_type" do
      it "sets the chef_type attr on the class" do
        subject.set_chef_type("environment")

        expect(subject.chef_type).to eql("environment")
      end
    end

    describe "::set_chef_json_class" do
      it "sets the chef_json_class attr on the class" do
        subject.set_chef_json_class("Chef::Environment")

        expect(subject.chef_json_class).to eql("Chef::Environment")
      end
    end

    describe "::set_chef_id" do
      it "sets the chef_id attribute on the class" do
        subject.set_chef_id(:environment)

        expect(subject.chef_id).to eql(:environment)
      end
    end

    describe "::chef_type" do
      it "returns the underscored name of the including class if nothing is set" do
        expect(subject.chef_type).to eql(subject.class.name.underscore)
      end
    end

    describe "::chef_json_class" do
      it "returns the chef_json if nothing has been set" do
        expect(subject.chef_json_class).to be_nil
      end
    end

    describe "::chef_id" do
      it "returns nil if nothing is set" do
        expect(subject.chef_id).to be_nil
      end
    end
  end

  subject do
    Class.new(described_class).new(resource)
  end

  describe "#save" do
    context "when the object is valid" do
      before(:each) { allow(subject).to receive(:valid?).and_return(true) }

      it "sends a create message to the implementing class" do
        updated = double('updated')
        allow(updated).to receive(:_attributes_).and_return(Hash.new)
        expect(resource).to receive(:create).with(subject).and_return(updated)

        subject.save
      end

      context "when there is an HTTPConflict" do
        it "sends the update message to self" do
          updated = double('updated')
          allow(updated).to receive(:[]).and_return(Hash.new)
          allow(updated).to receive(:_attributes_).and_return(Hash.new)
          expect(resource).to receive(:create).and_raise(Ridley::Errors::HTTPConflict.new(updated))
          expect(subject).to receive(:update).and_return(updated)

          subject.save
        end
      end
    end

    context "when the object is invalid" do
      before(:each) { allow(subject).to receive(:valid?).and_return(false) }

      it "raises an InvalidResource error" do
        expect {
          subject.save
        }.to raise_error(Ridley::Errors::InvalidResource)
      end
    end
  end

  describe "#update" do
    context "when the object is valid" do
      let(:updated) do
        updated = double('updated')
        allow(updated).to receive(:[]).and_return(Hash.new)
        allow(updated).to receive(:_attributes_).and_return(Hash.new)
        updated
      end

      before(:each) { allow(subject).to receive(:valid?).and_return(true) }

      it "sends an update message to the implementing class" do
        expect(resource).to receive(:update).with(subject).and_return(updated)
        subject.update
      end

      it "returns true" do
        expect(resource).to receive(:update).with(subject).and_return(updated)
        expect(subject.update).to eql(true)
      end
    end

    context "when the object is invalid" do
      before(:each) { allow(subject).to receive(:valid?).and_return(false) }

      it "raises an InvalidResource error" do
        expect {
          subject.update
        }.to raise_error(Ridley::Errors::InvalidResource)
      end
    end
  end

  describe "#chef_id" do
    it "returns the value of the chef_id attribute" do
      subject.class.attribute(:name)
      allow(subject.class).to receive(:chef_id) { :name }
      subject.mass_assign(name: "reset")

      expect(subject.chef_id).to eql("reset")
    end
  end

  describe "#reload" do
    let(:updated_subject) { double('updated_subject', _attributes_: { one: "val" }) }

    before(:each) do
      subject.class.attribute(:one)
      subject.class.attribute(:two)
      allow(resource).to receive(:find).with(subject).and_return(updated_subject)
    end

    it "returns itself" do
      expect(subject.reload).to eql(subject)
    end

    it "sets the attributes of self to equal those of the updated object" do
      subject.reload

      expect(subject.get_attribute(:one)).to eql("val")
    end

    it "does not include attributes not set by the updated object" do
      subject.two = "other"
      subject.reload
      expect(subject.two).to be_nil
    end
  end

  describe "comparable" do
    subject do
      Class.new(described_class) do
        set_chef_id "name"

        attribute "name"
        attribute "other_extra"
        attribute "extra"
      end
    end

    let(:one) { subject.new(resource) }
    let(:two) { subject.new(resource) }

    context "given two objects with the same value for their 'chef_id'" do
      before(:each) do
        one.mass_assign(name: "reset", other_extra: "stuff")
        two.mass_assign(name: "reset", extra: "stuff")
      end

      it "is equal" do
        expect(one).to be_eql(two)
      end
    end

    context "given two objects with different values for their 'chef_id'" do
      before(:each) do
        one.mass_assign(name: "jamie", other_extra: "stuff")
        two.mass_assign(name: "winsor", extra: "stuff")
      end

      it "is not equal" do
        expect(one).not_to be_eql(two)
      end
    end
  end

  describe "uniqueness" do
    subject do
      Class.new(described_class) do
        set_chef_id "name"

        attribute "name"
        attribute "other_extra"
        attribute "extra"
      end
    end

    let(:one) { subject.new(resource) }
    let(:two) { subject.new(resource) }

    context "given an array of objects with the same value for their 'chef_id'" do
      let(:nodes) do
        one.mass_assign(name: "reset", other_extra: "stuff")
        two.mass_assign(name: "reset", extra: "stuff")

        [ one, two ]
      end

      it "returns only one unique element" do
        expect(nodes.uniq.size).to eq(1)
      end
    end

    context "given an array of objects with different values for their 'chef_id'" do
      let(:nodes) do
        one.mass_assign(name: "jamie", other_extra: "stuff")
        two.mass_assign(name: "winsor", extra: "stuff")

        [ one, two ]
      end

      it "returns all of the elements" do
        expect(nodes.uniq.size).to eq(2)
      end
    end
  end
end
