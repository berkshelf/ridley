require 'spec_helper'

describe Ridley::SSH do
  let(:connection) { double('conn', ssh: { user: "vagrant", password: "vagrant" }) }

  let(:node_one) do
    Ridley::Node.new(connection, automatic: { cloud: { public_hostname: "33.33.33.10" } })
  end

  let(:node_two) do
    Ridley::Node.new(connection, automatic: { cloud: { public_hostname: "33.33.33.11" } })
  end

  describe "ClassMethods" do
    subject { Ridley::SSH }
    
    describe "::start" do
      pending
    end
  end

  subject { Ridley::SSH.new([node_one, node_two], user: "vagrant", password: "vagrant") }

  describe "#workers" do
    pending
  end

  describe "#run" do
    pending
  end
end
