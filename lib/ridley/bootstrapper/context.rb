require 'erubis'

module Ridley
  class Bootstrapper
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Context
      # @return [String]
      attr_reader :node_name
      # @return [Ridley::Connection]
      attr_reader :connection

      attr_reader :validation_client_name
      attr_reader :bootstrap_proxy
      attr_reader :hints
      attr_reader :chef_version
      attr_reader :environment
      attr_reader :client_path

      def initialize(node_name, connection, options = {})
        @node_name                      = node_name
        @connection                     = connection
        @validator_path                 = options.fetch(:validator_path) {
          raise ArgumentError, "A path to a validator is required for bootstrapping"
        }
        @bootstrap_proxy                = options.fetch(:bootstrap_proxy, nil)
        @encrypted_data_bag_secret_path = options.fetch(:encrypted_data_bag_secret_path, nil)
        @hints                          = options.fetch(:hints, Array.new)
        @attributes                     = options.fetch(:attributes, Hash.new)
        @run_list                       = options.fetch(:run_list, Array.new)
        @chef_version                   = options.fetch(:chef_version, Ridley::CHEF_VERSION)
        @environment                    = options.fetch(:environment, "_default")
        @client_path                    = options.fetch(:client_path, "chef-client")
        @sudo                           = options.fetch(:sudo, true)
        @template_file                  = options.fetch(:template, Bootstrapper.default_template)
      end

      # @return [String]
      def boot_command
        cmd = template.evaluate(self)

        if sudo
          cmd = "sudo #{cmd}"
        end

        cmd
      end

      # @return [String]
      def chef_run
        "#{client_path} -j /etc/chef/first-boot.json -E #{environment}"
      end

      # @return [String]
      def chef_config
        body = <<-CONFIG
log_level        :info
log_location     STDOUT
chef_server_url  "#{connection.server_url}"
validation_client_name "#{connection.validator_client}"
CONFIG

        if node_name.present?
          body << %Q{node_name "#{node_name}"\n}
        else
          body << "# Using default node name (fqdn)\n"
        end

        if bootstrap_proxy.present?
          body << %Q{http_proxy        "#{bootstrap_proxy}"\n}
          body << %Q{https_proxy       "#{bootstrap_proxy}"\n}
        end

        if encrypted_data_bag_secret.present?
          body << %Q{encrypted_data_bag_secret "/etc/chef/encrypted_data_bag_secret"\n}
        end

        body
      end

      # @return [String]
      def first_boot
        attributes.merge(run_list: run_list).to_json
      end

      # @raise [Ridley::Errors::ValidatorNotFound]
      #
      # @return [String]
      def validation_key
        IO.read(validator_path).chomp
      rescue Errno::ENOENT
        raise Errors::ValidatorNotFound, "Error bootstrapping: Validator not found at '#{validator_path}'"
      end

      # @raise [Ridley::Errors::EncryptedDataBagSecretNotFound]
      #
      # @return [String, nil]
      def encrypted_data_bag_secret
        return nil if encrypted_data_bag_secret_path.nil?

        IO.read(encrypted_data_bag_secret_path).chomp
      rescue Errno::ENOENT => encrypted_data_bag_secret
        raise Errors::EncryptedDataBagSecretNotFound, "Error bootstrapping: Encrypted data bag secret provided but not found at '#{encrypted_data_bag_secret_path}"
      end

      private

        attr_reader :sudo
        attr_reader :template_file
        attr_reader :encrypted_data_bag_secret_path
        attr_reader :validator_path
        attr_reader :run_list
        attr_reader :attributes

        # @return [Erubis::Eruby]
        def template
          Erubis::Eruby.new(IO.read(template_file).chomp)
        end
    end
  end
end
