require 'spec_helper'

describe Ridley::Environment do
  it_behaves_like "a Ridley Resource", Ridley::Environment

  let(:environment_json) do
    %(
      {
        "name": "crazy-town",
        "default_attributes": {
          "nested_attribute": {
            "status": "running",
            "list": [
              "one-thing"
            ],
            "feelin_good": true
          }
        },
        "description": "Single letter variables. Who the fuck do you think you are?",
        "cookbook_versions": {

        },
        "override_attributes": {
          "mysql": {
            "bind_address": "127.0.0.1",
            "server_root_password": "password_lol"
          }
        },
        "chef_type": "environment"
      }
    )
  end

  describe "ClassMethods" do
    subject { Ridley::Environment }

    describe "::initialize" do
      before(:each) do
        @env = subject.new(parse_json(environment_json))
      end

      it "has a value for 'name'" do
        @env.name.should eql("crazy-town")
      end

      it "has a value for 'default_attributes'" do
        @env.default_attributes.should be_a(Hash)
        @env.default_attributes.should have_key("nested_attribute")
        @env.default_attributes["nested_attribute"]["status"].should eql("running")
      end

      it "has a value for 'description'" do
        @env.description.should eql("Single letter variables. Who the fuck do you think you are?")
      end

      it "has a value for 'cookbook_version'" do
        @env.cookbook_versions.should be_a(Hash)
      end

      it "has a value for 'override_attributes'" do
        @env.override_attributes.should be_a(Hash)
        @env.override_attributes.should have_key("mysql")
        @env.override_attributes["mysql"].should have_key("bind_address")
      end

      it "has a value for 'chef_type'" do
        @env.chef_type.should eql("environment")
      end
    end
  end
end
