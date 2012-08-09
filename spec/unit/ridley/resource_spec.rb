require 'spec_helper'

describe Ridley::Resource do
  describe "ClassMethods" do
    subject do
      Class.new do
        include Ridley::Resource
      end
    end

    describe "::initialize" do
      it "has an empty Hash for attributes if no attributes have been defined" do
        klass = subject.new

        klass.attributes.should be_empty
      end

      it "assigns the given attributes to the attribute hash if the attribute is defined on the class" do
        subject.attribute(:name)
        klass = subject.new(name: "a name")

        klass.name.should eql("a name")
        klass.attributes.should have_key(:name)
      end

      it "skips attributes which are not defined on the class when assigning attributes" do
        klass = subject.new(fake: "not here")

        klass.attributes.should_not have_key(:fake)
      end

      it "merges the default values for attributes into the attributes hash" do
        subject.should_receive(:attribute_defaults).and_return(name: "whatever")
        subject.attribute(:name, deafult: "whatever")
        klass = subject.new

        klass.attributes[:name].should eql("whatever")
      end
    end

    describe "::chef_id" do
      it "returns nil if nothing is set" do
        subject.chef_id.should be_nil
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
        subject.chef_type.should eql("class")
      end
    end

    describe "::set_chef_type" do
      it "sets the chef_type attr on the class" do
        subject.set_chef_type("environment")

        subject.chef_type.should eql("environment")
      end
    end

    describe "::resource_path" do
      it "returns the underscored and plural name of the including class if nothing is set" do
        subject.resource_path.should eql("classes")
      end
    end

    describe "::set_resource_path" do
      it "sets the resource_path attr on the class" do
        subject.set_resource_path("environments")

        subject.resource_path.should eql("environments")
      end
    end

    describe "::chef_json_class" do
      it "returns nil if nothing has been set" do
        subject.chef_json_class.should be_nil
      end
    end

    describe "::set_chef_json_class" do
      it "sets the chef_json_class attr on the class" do
        subject.set_chef_json_class("Chef::Environment")

        subject.chef_json_class.should eql("Chef::Environment")
      end

      it "sets the value of the :json_class attribute default to the given value" do
        subject.set_chef_json_class("Chef::Environment")

        subject.attribute_defaults.should have_key(:json_class)
        subject.attribute_defaults[:json_class].should eql("Chef::Environment")
      end
    end

    describe "::attributes" do
      it "returns a Set" do
        subject.attributes.should be_a(Set)
      end
    end

    describe "::attribute" do
      pending
    end

    describe "::all" do
      pending
    end

    describe "::find" do
      pending
    end

    describe "::create" do
      pending
    end

    describe "::delete" do
      pending
    end

    describe "::update" do
      pending
    end
  end

  subject do
    Class.new do
      include Ridley::Resource
    end.new
  end

  describe "#attribute" do
    pending
  end

  describe "#attribute=" do
    pending
  end

  describe "#attribute?" do
    pending
  end

  describe "#attributes" do
    it "returns a hash of attributes" do
      subject.attributes.should be_a(Hash)
    end

    it "includes attribute_defaults in the attributes" do
      subject.class.stub(:attributes).and_return(Set.new([:val_one]))
      subject.class.stub(:attribute_defaults).and_return(val_one: "value")

      subject.attributes.should have_key(:val_one)
      subject.attributes[:val_one].should eql("value")
    end
  end

  describe "#attributes=" do
    pending
  end

  describe "#save" do
    pending
  end

  describe "#to_json" do
    pending
  end
end
