require 'spec_helper'

describe Ridley::Resource do
  describe "ClassMethods" do
    subject do
      Class.new do
        include Ridley::Resource
      end
    end

    it_behaves_like "a Ridley Resource", subject.call

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
        subject.stub(:attributes).and_return(Set.new([:name]))
        subject.should_receive(:attribute_defaults).and_return(name: "whatever")
        klass = subject.new

        klass.attributes[:name].should eql("whatever")
      end

      it "explicit attributes take precedence over defaults" do
        subject.stub(:attributes).and_return(Set.new([:name]))
        subject.stub(:attribute_defaults).and_return(name: "default")

        klass = subject.new(name: "explicit_name")

        klass.attributes[:name].should eql("explicit_name")
      end
    end

    describe "::attributes" do
      it "returns a Set" do
        subject.attributes.should be_a(Set)
      end
    end

    describe "::attribute" do
      it "adds the given symbol to the attributes Set" do
        subject.attribute(:name)

        subject.attributes.should include(:name)
      end

      it "convers the given string into a symbol and adds it to the attributes Set" do
        subject.attribute('last_name')

        subject.attributes.should include(:last_name)
      end

      describe "setting a default value for the attribute" do
        it "allows a string as the default value for the attribute" do
          subject.attribute(:name, default: "jamie")

          subject.attribute_defaults[:name].should eql("jamie")
        end

        it "allows a false boolean as the default value for the attribute" do
          subject.attribute(:admin, default: false)

          subject.attribute_defaults[:admin].should eql(false)
        end

        it "allows a true boolean as the default value for the attribute" do
          subject.attribute(:admin, default: true)

          subject.attribute_defaults[:admin].should eql(true)
        end

        it "allows nil as the default value for the attribute" do
          subject.attribute(:certificate, default: nil)

          subject.attribute_defaults[:certificate].should be_nil
        end
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

      it "sets the value of the :json_class attribute default to the given value" do
        subject.set_chef_json_class("Chef::Environment")

        subject.attribute_defaults.should have_key(:json_class)
        subject.attribute_defaults[:json_class].should eql("Chef::Environment")
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
    Class.new do
      include Ridley::Resource
    end.new
  end

  describe "#attribute?" do
    context "if the class has the attribute defined" do
      before(:each) do
        subject.class.attribute(:name)
      end

      it "returns false if the attribute has no value" do
        subject.name = nil

        subject.attribute?(:name).should be_false
      end

      it "returns true if the attribute has a value" do
        subject.name = "reset"

        subject.attribute?(:name).should be_true
      end
    end

    context "if the class has the attribute defined with a default value" do
      before(:each) do
        subject.class.attribute(:name, default: "exception")
      end

      it "returns true if the attribute has not been explicitly set" do
        subject.attribute?(:name).should be_true
      end
    end

    context "if the class does not have the attribute defined" do
      it "returns false" do
        subject.attribute?(:name).should be_false
      end
    end
  end

  describe "#attributes=" do
    it "assigns the hash of attributes to the objects attributes" do
      subject.class.attribute(:name)
      subject.attributes = { name: "reset" }

      subject.attributes[:name].should eql("reset")
    end
  end
end
