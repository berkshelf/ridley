require 'spec_helper'

describe Ridley do
  let(:config) { double("config") }

  describe "ClassMethods" do
    subject { Ridley }

    describe "::new" do
      it "creates a new Ridley::Connection" do
        client = double('client')
        Ridley::Client.should_receive(:new).with(config).and_return(client)

        subject.new(config).should eql(client)
      end
    end

    describe "from_chef_config" do
      let(:chef_config) do
        %(
          node_name                "username"
          client_key               "username.pem"
          validation_client_name   "validator"
          validation_key           "validator.pem"
          chef_server_url          "https://api.opscode.com"
          cache_options(:path => "~/.chef/checksums")
          syntax_check_cache_path  "/foo/bar"
        )
      end

      let(:client) { double('client') }
      let(:path) { tmp_path.join('config.rb').to_s }

      before do
        Ridley::Client.stub(:new).and_return(client)
        File.open(path, 'w') { |f| f.write(chef_config) }
      end

      it "creates a Ridley connection from the Chef config" do
        Ridley::Client.should_receive(:new).with({
          client_key: 'username.pem',
          client_name: 'username',
          validator_client: 'validator',
          validator_path: 'validator.pem',
          server_url: 'https://api.opscode.com',

          cookbook_copyright: 'YOUR_NAME',
          cookbook_email: 'YOUR_EMAIL',
          cookbook_license: 'reserved',

          knife: {},

          syntax_check_cache_path: "/foo/bar",
          cache_options: { path: "~/.chef/checksums" },
        }).and_return(nil)

        subject.from_chef_config(path)
      end

      it "allows the user to override attributes" do
        Ridley::Client.should_receive(:new).with({
          client_key: 'bacon.pem',
          client_name: 'bacon',
          validator_client: 'validator',
          validator_path: 'validator.pem',
          server_url: 'https://api.opscode.com',

          cookbook_copyright: 'YOUR_NAME',
          cookbook_email: 'YOUR_EMAIL',
          cookbook_license: 'reserved',

          knife: {},

          syntax_check_cache_path: "/foo/bar",
          cache_options: { path: "~/.chef/checksums" },
        })

        subject.from_chef_config(path, client_key: 'bacon.pem', client_name: 'bacon')
      end

      context "when the config location isn't explicitly specified" do
        before do
          dot_chef = tmp_path.join('.chef')
          knife_rb = dot_chef.join('knife.rb')

          FileUtils.mkdir_p(dot_chef)
          File.open(knife_rb, 'w') { |f| f.write(chef_config) }
        end

        it "does a knife.rb search" do
          Ridley::Client.should_receive(:new).with({
            client_key: 'username.pem',
            client_name: 'username',
            validator_client: 'validator',
            validator_path: 'validator.pem',
            server_url: 'https://api.opscode.com',

            cookbook_copyright: 'YOUR_NAME',
            cookbook_email: 'YOUR_EMAIL',
            cookbook_license: 'reserved',

            knife: {},

            syntax_check_cache_path: "/foo/bar",
            cache_options: { path: "~/.chef/checksums" },
          }).and_return(nil)

          Dir.chdir(tmp_path) do
            ENV['PWD'] = Dir.pwd
            subject.from_chef_config
          end
        end
      end
    end
  end
end
