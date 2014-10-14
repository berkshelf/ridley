require 'spec_helper'

describe Ridley::NodeResource do
  let(:instance) do
    inst = described_class.new(double)
    inst.stub(connection: chef_zero_connection)
    inst
  end

  describe "#merge_data" do
    let(:node_name) { "rspec-test" }
    let(:run_list) { [ "recipe[one]", "recipe[two]" ] }
    let(:attributes) { { deep: { two: "val" } } }

    subject(:result) { instance.merge_data(node_name, run_list: run_list, attributes: attributes) }

    context "when a node of the given name exists" do
      before do
        chef_node(node_name,
          run_list: [ "recipe[one]", "recipe[three]" ],
          normal: { deep: { one: "val" } }
        )
      end

      it "returns a Ridley::NodeObject" do
        expect(result).to be_a(Ridley::NodeObject)
      end

      it "has a union between the run list of the original node and the new run list" do
        expect(result.run_list).to eql(["recipe[one]","recipe[three]","recipe[two]"])
      end

      it "has a deep merge between the attributes of the original node and the new attributes" do
        expect(result.normal.to_hash).to eql("deep" => { "one" => "val", "two" => "val" })
      end
    end

    context "when a node with the given name does not exist" do
      let(:node_name) { "does_not_exist" }

      it "raises a ResourceNotFound error" do
        expect { result }.to raise_error(Ridley::Errors::ResourceNotFound)
      end
    end
  end
end
