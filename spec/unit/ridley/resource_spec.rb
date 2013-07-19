require 'spec_helper'

describe Ridley::Resource do
  let(:representation) do
    Class.new(Ridley::ChefObject) do
      set_chef_id "id"
      set_chef_type "thing"
      set_chef_json_class "Chef::Thing"
    end
  end

  let(:resource_class) do
    Class.new(Ridley::Resource) do
      set_resource_path "rspecs"
    end
  end

  describe "ClassMethods" do
    subject { resource_class }

    describe "::set_resource_path" do
      it "sets the resource_path attr on the class" do
        subject.set_resource_path("environments")

        subject.resource_path.should eql("environments")
      end
    end

    describe "::resource_path" do
      context "when not explicitly set" do
        before { subject.set_resource_path(nil) }

        it "returns the representation's chef type" do
          subject.resource_path.should eql(representation.chef_type)
        end
      end

      context "when explicitly set" do
        let(:set_path) { "hello" }
        before { subject.set_resource_path(set_path) }

        it "returns the set value" do
          subject.resource_path.should eql(set_path)
        end
      end
    end
  end

  let(:connection) { double('chef-connection') }
  let(:response) { double('chef-response', body: Hash.new) }
  let(:resource_json) { '{"some":"valid json"}' }

  subject { resource_class.new(double('registry')) }

  before do
    resource_class.stub(representation: representation)
    subject.stub(connection: connection)
  end

  describe "::from_file" do
    it "reads the file and calls ::from_json with contents" do
      File.stub(:read) { resource_json }
      subject.should_receive(:from_json).with(resource_json)
      subject.from_file('/bogus/filename.json')
    end
  end

  describe "::from_json" do
    it "parses the argument and calls ::new with newly built hash" do
      hashed_json = JSON.parse(resource_json)
      subject.should_receive(:new).with(hashed_json).and_return representation
      subject.from_json(resource_json)
    end
  end

  describe "::all" do
    it "sends GET to /{resource_path}" do
      connection.should_receive(:get).with(subject.class.resource_path).and_return(response)

      subject.all
    end
  end

  describe "::find" do
    let(:id) { "some_id" }

    it "sends GET to /{resource_path}/{id} where {id} is the given ID" do
      connection.should_receive(:get).with("#{subject.class.resource_path}/#{id}").and_return(response)

      subject.find(id)
    end

    context "when the resource is not found" do
      before do
        connection.should_receive(:get).with("#{subject.class.resource_path}/#{id}").
          and_raise(Ridley::Errors::HTTPNotFound.new({}))
      end

      it "returns nil" do
        subject.find(id).should be_nil
      end
    end
  end

  describe "::create" do
    let(:attrs) do
      {
        first_name: "jamie",
        last_name: "winsor"
      }
    end

    it "sends a post request to the given client using the includer's resource_path" do
      connection.should_receive(:post).with(subject.class.resource_path, duck_type(:to_json)).and_return(response)

      subject.create(attrs)
    end
  end

  describe "::delete" do
    it "sends a delete request to the given client using the includer's resource_path for the given string" do
      connection.should_receive(:delete).with("#{subject.class.resource_path}/ridley-test").and_return(response)

      subject.delete("ridley-test")
    end

    it "accepts an object that responds to 'chef_id'" do
      object = double("obj")
      object.stub(:chef_id) { "hello" }
      connection.should_receive(:delete).with("#{subject.class.resource_path}/#{object.chef_id}").and_return(response)

      subject.delete( object)
    end
  end

  describe "::delete_all" do
    it "sends a delete request for every object in the collection" do
      pending
    end
  end

  describe "::update" do
    it "sends a put request to the given client using the includer's resource_path with the given object" do
      object = subject.new(name: "hello")
      connection.should_receive(:put).
        with("#{subject.class.resource_path}/#{object.chef_id}", duck_type(:to_json)).and_return(response)

      subject.update(object)
    end
  end
end
