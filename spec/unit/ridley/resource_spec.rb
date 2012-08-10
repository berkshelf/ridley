require 'spec_helper'

describe Ridley::Resource do
  describe "ClassMethods" do
    subject do
      Class.new do
        include Ridley::Resource
      end
    end

    let(:active_connection) { double('active-connection') }
    let(:response) { double('response') }

    before(:each) do
      Ridley::Connection.stub(:active).and_return(active_connection)
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
      it "sends a get request for the class' resource_path using the active connection" do
        response.stub(:body) { Hash.new }
        active_connection.should_receive(:get).with(subject.resource_path).and_return(response)
        
        subject.all
      end
    end

    describe "::find" do
      it "sends a get request to the active connection to the resource_path of the class for the given chef_id" do
        chef_id = "ridley_test"
        response.stub(:body) { Hash.new }
        active_connection.should_receive(:get).with("#{subject.resource_path}/#{chef_id}").and_return(response)

        subject.find(chef_id)
      end
    end

    describe "::create" do
      it "sends a post request to the active connection using the includer's resource_path" do
        attrs = {
          first_name: "jamie",
          last_name: "winsor"
        }

        response.stub(:body) { attrs }
        active_connection.should_receive(:post).with(subject.resource_path, duck_type(:to_json)).and_return(response)

        subject.create(attrs)
      end
    end

    describe "::delete" do
      it "sends a delete request to the active connection using the includer's resource_path for the given string" do
        response.stub(:body) { Hash.new }
        active_connection.should_receive(:delete).with("#{subject.resource_path}/ridley-test").and_return(response)

        subject.delete("ridley-test")
      end

      it "accepts an object that responds to 'chef_id'" do
        object = double("obj")
        object.stub(:chef_id) { "hello" }
        response.stub(:body) { Hash.new }
        active_connection.should_receive(:delete).with("#{subject.resource_path}/#{object.chef_id}").and_return(response)

        subject.delete(object)
      end
    end

    describe "::update" do
      it "sends a put request to the active connection using the includer's resource_path with the given object" do
        subject.stub(:chef_id) { :name }
        subject.attribute(:name)
        object = subject.new(name: "hello")
        response.stub(:body) { Hash.new }
        active_connection.should_receive(:put).with("#{subject.resource_path}/#{object.chef_id}", duck_type(:to_json)).and_return(response)

        subject.update(object)
      end
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

  describe "#chef_id" do
    it "returns the value of the chef_id attribute" do
      subject.class.attribute(:name)
      subject.class.stub(:chef_id) { :name }
      subject.attributes = { name: "reset" }

      subject.chef_id.should eql("reset")
    end
  end

  describe "#from_hash" do
    before(:each) do
      subject.class.attribute(:name)
      @object = subject.from_hash(name: "reset")
    end

    it "returns an instance of the implementing class" do
      @object.should be_a(subject.class)
    end

    it "assigns the attributes to the values of the corresponding keys in the given Hash" do
      @object.name.should eql("reset")
    end
  end

  describe "#to_hash" do
    it "returns a hash" do
      subject.to_hash.should be_a(Hash)
    end

    it "delegates to .attributes" do
      subject.should_receive(:attributes)

      subject.to_hash
    end
  end

  describe "#to_json" do
    it "returns valid JSON" do
      subject.to_json.should be_json_eql("{}")
    end
  end

  describe "#from_json" do
    before(:each) do
      subject.class.attribute(:name)
      @object = subject.from_json(%({"name": "reset"}))
    end

    it "returns an instance of the implementing class" do
      @object.should be_a(subject.class)
    end

    it "assigns the attributes to the values of the corresponding keys in the given JSON" do
      @object.name.should eql("reset")
    end
  end
end
