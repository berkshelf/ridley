require 'spec_helper'

describe Ridley::Bootstrapper do
  let(:connection) do
    double('conn',
      server_url: "https://api.opscode.com/organizations/vialstudios",
      validator_client: "vialstudios-validator",
      ssh: {
        user: "reset",
        password: "lol"
      }
    )
  end

  let(:nodes) do
    [
      "33.33.33.10"
    ]
  end

  let(:options) do
    {
      validator_path: fixtures_path.join("reset.pem").to_s,
      encrypted_data_bag_secret_path: fixtures_path.join("reset.pem").to_s
    }
  end

  describe "ClassMethods" do
    subject { Ridley::Bootstrapper }

    describe "::new" do
      context "given a single string for nodes" do
        before(:each) do
          @obj = subject.new(connection, "33.33.33.10", options)
        end

        it "has one node" do
          @obj.hosts.should have(1).item
        end

        it "has one context" do
          @obj.contexts.should have(1).item
        end
      end

      context "given an an array of strings nodes" do
        before(:each) do
          @obj = subject.new(connection, ["33.33.33.10", "33.33.33.11"], options)
        end

        it "has a host for each item given" do
          @obj.hosts.should have(2).items
        end

        it "has a context for each item given" do
          @obj.contexts.should have(2).items
        end
      end
    end

    describe "::templates_path" do
      it "returns a pathname" do
        subject.templates_path.should be_a(Pathname)
      end
    end

    describe "::default_template" do
      it "returns a string" do
        subject.default_template.should be_a(String)
      end
    end
  end

  subject { Ridley::Bootstrapper.new(connection, nodes, options) }

  describe "#hosts" do
    it "returns an array of strings" do
      subject.hosts.should be_a(Array)
      subject.hosts.should each be_a(String)
    end
  end

  describe "#contexts" do
    it "returns an array of Bootstrapper::Contexts" do
      subject.contexts.should be_a(Array)
      subject.contexts.should each be_a(Ridley::Bootstrapper::Context)
    end
  end

  describe "#run" do
    let(:options) do
      {
        validator_path: "/Users/reset/.chef/vialstudios-validator.pem"
      }
    end

    subject { Ridley::Bootstrapper.new(connection, nodes, options) }

    before(:each) do
      subject.ssh_config[:timeout] = 0.5
      subject.ssh_config[:user] = "vagrant"
      subject.ssh_config[:password] = "vagrant"
    end

    it "returns an array of response objects", focus: true do
      p subject.contexts
      result = subject.run

      puts result.first[1].stdout

      result.should be_a(Array)
    end
  end
end
