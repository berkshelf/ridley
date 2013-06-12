describe Ridley::ChefObject do
  let(:resource) { double('chef-resource') }

  describe "ClassMethods" do
    subject { Class.new(described_class) }

    describe "::new" do
      it "mass assigns the given attributes" do
        new_attrs = {
          name: "a name"
        }

        subject.any_instance.should_receive(:mass_assign).with(new_attrs)
        subject.new(resource, new_attrs)
      end
    end

    describe "::set_chef_type" do
      it "sets the chef_type attr on the class" do
        subject.set_chef_type("environment")

        subject.chef_type.should eql("environment")
      end
    end

    describe "::set_chef_json_class" do
      it "sets the chef_json_class attr on the class" do
        subject.set_chef_json_class("Chef::Environment")

        subject.chef_json_class.should eql("Chef::Environment")
      end
    end

    describe "::set_chef_id" do
      it "sets the chef_id attribute on the class" do
        subject.set_chef_id(:environment)

        subject.chef_id.should eql(:environment)
      end
    end

    describe "::chef_type" do
      it "returns the underscored name of the including class if nothing is set" do
        subject.chef_type.should eql(subject.class.name.underscore)
      end
    end

    describe "::chef_json_class" do
      it "returns the chef_json if nothing has been set" do
        subject.chef_json_class.should be_nil
      end
    end

    describe "::chef_id" do
      it "returns nil if nothing is set" do
        subject.chef_id.should be_nil
      end
    end
  end

  subject do
    Class.new(described_class).new(resource)
  end

  describe "#save" do
    context "when the object is valid" do
      before(:each) { subject.stub(:valid?).and_return(true) }

      it "sends a create message to the implementing class" do
        updated = double('updated')
        updated.stub(:_attributes_).and_return(Hash.new)
        resource.should_receive(:create).with(subject).and_return(updated)

        subject.save
      end

      context "when there is an HTTPConflict" do
        it "sends the update message to self" do
          updated = double('updated')
          updated.stub(:[]).and_return(Hash.new)
          updated.stub(:_attributes_).and_return(Hash.new)
          resource.should_receive(:create).and_raise(Ridley::Errors::HTTPConflict.new(updated))
          subject.should_receive(:update).and_return(updated)

          subject.save
        end
      end
    end

    context "when the object is invalid" do
      before(:each) { subject.stub(:valid?).and_return(false) }

      it "raises an InvalidResource error" do
        lambda {
          subject.save
        }.should raise_error(Ridley::Errors::InvalidResource)
      end
    end
  end

  describe "#update" do
    context "when the object is valid" do
      let(:updated) do
        updated = double('updated')
        updated.stub(:[]).and_return(Hash.new)
        updated.stub(:_attributes_).and_return(Hash.new)
        updated
      end

      before(:each) { subject.stub(:valid?).and_return(true) }

      it "sends an update message to the implementing class" do
        resource.should_receive(:update).with(subject).and_return(updated)
        subject.update
      end

      it "returns true" do
        resource.should_receive(:update).with(subject).and_return(updated)
        subject.update.should eql(true)
      end
    end

    context "when the object is invalid" do
      before(:each) { subject.stub(:valid?).and_return(false) }

      it "raises an InvalidResource error" do
        lambda {
          subject.update
        }.should raise_error(Ridley::Errors::InvalidResource)
      end
    end
  end

  describe "#chef_id" do
    it "returns the value of the chef_id attribute" do
      subject.class.attribute(:name)
      subject.class.stub(:chef_id) { :name }
      subject.mass_assign(name: "reset")

      subject.chef_id.should eql("reset")
    end
  end

  describe "#reload" do
    let(:updated_subject) { double('updated_subject', _attributes_: { one: "val" }) }

    before(:each) do
      subject.class.attribute(:one)
      subject.class.attribute(:two)
      resource.stub(:find).with(subject).and_return(updated_subject)
    end

    it "returns itself" do
      subject.reload.should eql(subject)
    end

    it "sets the attributes of self to equal those of the updated object" do
      subject.reload

      subject.get_attribute(:one).should eql("val")
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
        one.should be_eql(two)
      end
    end

    context "given two objects with different values for their 'chef_id'" do
      before(:each) do
        one.mass_assign(name: "jamie", other_extra: "stuff")
        two.mass_assign(name: "winsor", extra: "stuff")
      end

      it "is not equal" do
        one.should_not be_eql(two)
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
        nodes.uniq.should have(1).item
      end
    end

    context "given an array of objects with different values for their 'chef_id'" do
      let(:nodes) do
        one.mass_assign(name: "jamie", other_extra: "stuff")
        two.mass_assign(name: "winsor", extra: "stuff")

        [ one, two ]
      end

      it "returns all of the elements" do
        nodes.uniq.should have(2).item
      end
    end
  end
end
