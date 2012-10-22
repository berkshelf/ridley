require 'spec_helper'

describe Ridley::SSH, focus: true do
  let(:connection) { double('conn', ssh: { user: "vagrant", password: "vagrant" }) }

  let(:node_one) do
    Ridley::Node.new(connection, automatic: { cloud: { public_hostname: "33.33.33.10" } })
  end

  let(:node_two) do
    Ridley::Node.new(connection, automatic: { cloud: { public_hostname: "33.33.33.11" } })
  end

  subject { Ridley::SSH.new([node_one, node_two], "vagrant", password: "vagrant") }

  describe "#workers" do
    pending
  end

  describe "#run" do
    it "test" do
      result = node_one.chef_solo

      result.should be_a(Array)
      result.should have(2).items
      result[0].should eql(:error)
      result[1].should be_a(Ridley::SSH::Response)
    end

    it "other_test" do
      result = node_two.chef_solo

      result.should be_a(Array)
      result.should have(2).items
      result[0].should eql(:error)
      result[1].should be_a(Timeout::Error)
    end
  end
end
