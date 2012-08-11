shared_examples_for "a Ridley Resource" do |resource_klass|
  let(:active_connection) { double('active-connection') }
  let(:response) { double('response') }

  before(:each) do
    Ridley::Connection.stub(:active).and_return(active_connection)
  end

  describe "ClassMethods" do
    subject { resource_klass }

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

  subject { resource_klass.new }

  describe "#attribute" do
    it "returns the value of the attribute of the corresponding identifier" do
      subject.attributes.each do |attr, value|
        subject.attribute(attr).should eql(value)
      end
    end
  end

  describe "#attribute=" do
    it "assigns the desired to the attribute of the corresponding identifier" do
      subject.attributes.each do |attr, value|
        subject.send(:attribute=, attr, "testval")
      end

      subject.attributes.each do |attr, value|
        subject.attribute(attr).should eql("testval")
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

  describe "#save" do
    context "when the object is valid" do
      before(:each) { subject.stub(:valid?).and_return(true) }

      it "sends a create message to the implementing class" do
        subject.class.should_receive(:create).with(subject)

        subject.save
      end

      context "when there is an HTTPConflict" do
        it "sends an update message to the implemeneting class" do
          env = double('env')
          env.stub(:[]).and_return(Hash.new)
          subject.class.should_receive(:create).and_raise(Ridley::Errors::HTTPConflict.new(env))
          subject.class.should_receive(:update).with(subject)

          subject.save
        end
      end
    end

    context "when the object is invalid" do
      before(:each) { subject.stub(:valid?).and_return(false) }

      it "raises an InvalidObject error" do
        lambda {
          subject.save
        }.should raise_error(Ridley::Errors::InvalidResource)
      end
    end
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
    it "serializes the objects attributes using MultiJson" do
      MultiJson.should_receive(:dump).with(subject.attributes, kind_of(Hash))

      subject.to_json
    end

    it "returns the seralized value" do
      MultiJson.stub(:dump).and_return("{}")

      subject.to_json.should eql("{}")
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
