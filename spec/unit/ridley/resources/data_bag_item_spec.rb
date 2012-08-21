require 'spec_helper'

describe Ridley::DataBagItem do
  let(:connection) { double('connection') }
  let(:data_bag) { double('data_bag') }

  subject { Ridley::DataBagItem.new(connection, data_bag) }

  describe "::from_hash" do
    context "when JSON has a 'raw_data' field" do
      let(:response) do
        {
          name: "data_bag_item_ridley-test_appconfig",
          raw_data: {
            id: "appconfig",
            host: "host.local"
          },
          json_class: "Chef::DataBagItem",
          data_bag: "ridley-test",
          chef_type: "data_bag_item"
        }
      end

      it "returns a new object from attributes in the 'raw_data' field" do
        subject.from_hash(response).attributes.should eql(response[:raw_data])
      end
    end

    context "when JSON does not contain a 'raw_data' field" do
      let(:response) do
        {
          id: "appconfig",
          host: "host.local"
        }
      end

      it "returns a new object from the hash" do
        subject.from_hash(response).attributes.should eql(response)
      end
    end
  end
end
