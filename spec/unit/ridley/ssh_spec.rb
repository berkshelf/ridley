require 'spec_helper'

describe Ridley::SSH do
  let(:connection) { double('conn', ssh: { user: "vagrant", password: "vagrant" }) }

  let(:node_one) do
    Ridley::NodeResource.new(connection, automatic: { cloud: { public_hostname: "33.33.33.10" } })
  end

  let(:node_two) do
    Ridley::NodeResource.new(connection, automatic: { cloud: { public_hostname: "33.33.33.11" } })
  end

  describe "ClassMethods" do
    subject { Ridley::SSH }
    
    describe "::start" do
      let(:options) do
        {
          user: "vagrant",
          password: "vagrant"
        }
      end

      it "evaluates within the context of a new SSH and returns the last item in the block" do
        result = subject.start([node_one, node_two], options) do |ssh|
          ssh.run("ls")
        end

        result.should be_a(Ridley::SSH::ResponseSet)
      end

      it "raises a LocalJumpError if a block is not provided" do        
        expect {
          subject.start([node_one, node_two], options)
        }.to raise_error(LocalJumpError)
      end
    end
  end

  subject { Ridley::SSH.new([node_one, node_two], user: "vagrant", password: "vagrant") }

  describe "#run" do
    it "returns an SSH::ResponseSet" do
      subject.run("ls").should be_a(Ridley::SSH::ResponseSet)
    end
  end
end
