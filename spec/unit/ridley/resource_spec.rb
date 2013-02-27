require 'spec_helper'

describe Ridley::Resource do
  let(:connection) { double('connection') }
  
  describe "ClassMethods" do
    subject do
      Class.new(Ridley::Resource)
    end

    it_behaves_like "a Ridley Resource", Class.new(Ridley::Resource)

    describe "::initialize" do
      it "mass assigns the given attributes" do
        new_attrs = {
          name: "a name"
        }

        subject.any_instance.should_receive(:mass_assign).with(new_attrs)
        subject.new(connection, new_attrs)
      end
    end

    describe "::set_chef_type" do
      it "sets the chef_type attr on the class" do
        subject.set_chef_type("environment")

        subject.chef_type.should eql("environment")
      end
    end

    describe "::set_resource_path" do
      it "sets the resource_path attr on the class" do
        subject.set_resource_path("environments")

        subject.resource_path.should eql("environments")
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

    describe "::resource_path" do
      it "returns the underscored and plural name of the including class if nothing is set" do
        subject.resource_path.should eql(subject.class.name.underscore.pluralize)
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
    Class.new(Ridley::Resource).new(connection)
  end

  describe "comparable" do
    subject do
      Class.new(Ridley::Resource) do
        set_chef_id "name"

        attribute "name"
        attribute "other_extra"
        attribute "extra"
      end
    end

    let(:one) { subject.new(connection) }
    let(:two) { subject.new(connection) }

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
      Class.new(Ridley::Resource) do
        set_chef_id "name"

        attribute "name"
        attribute "other_extra"
        attribute "extra"
      end
    end

    let(:one) { subject.new(connection) }
    let(:two) { subject.new(connection) }

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
