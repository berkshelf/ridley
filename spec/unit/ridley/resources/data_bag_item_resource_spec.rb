require 'spec_helper'

describe Ridley::DataBagItemResource do
  let(:connection) { double('connection') }
  let(:data_bag) { double('data_bag') }

  subject { Ridley::DataBagItemResource.new(connection, data_bag) }

  describe "::from_hash" do
    context "when JSON has a 'raw_data' field" do
      let(:response) do
        {
          "name" => "data_bag_item_ridley-test_appconfig",
          "raw_data" => {
            "id" => "appconfig",
            "host" => "host.local"
          },
          "json_class" => "Chef::DataBagItem",
          "data_bag" => "ridley-test",
          "chef_type" => "data_bag_item"
        }
      end

      it "returns a new object from attributes in the 'raw_data' field" do
        subject.from_hash(response).attributes.should eql(response["raw_data"])
      end
    end

    context "when JSON does not contain a 'raw_data' field" do
      let(:response) do
        {
          "id" => "appconfig",
          "host" => "host.local"
        }
      end

      it "returns a new object from the hash" do
        subject.from_hash(response).attributes.should eql(response)
      end
    end
  end

  describe "#decrypt" do
    before(:each) do
      encrypted_data_bag_secret = File.read(fixtures_path.join("encrypted_data_bag_secret").to_s)
      connection.stub(:encrypted_data_bag_secret).and_return(encrypted_data_bag_secret)
    end

    it "decrypts an encrypted value" do
      subject.attributes[:test] = "Xk0E8lV9r4BhZzcg4wal0X4w9ZexN3azxMjZ9r1MCZc="
      subject.decrypt
      subject.attributes[:test][:database][:username].should == "test"
    end

    it "does not decrypt the id field" do
      id = "dbi_id"
      subject.attributes[:id] = id
      subject.decrypt
      subject.attributes[:id].should == id
    end
  end
end
