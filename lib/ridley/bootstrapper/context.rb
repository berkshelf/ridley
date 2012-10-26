require 'erubis'

module Ridley
  class Bootstrapper
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Context
      # @return [String]
      attr_reader :node_name
      # @return [Ridley::Connection]
      attr_reader :connection
      # @return [String]
      attr_reader :validation_client_name
      # @return [String]
      attr_reader :bootstrap_proxy
      # @return [Hash]
      attr_reader :hints
      # @return [String]
      attr_reader :chef_version
      # @return [String]
      attr_reader :environment

      # @param [Ridley::Connection] connection
      # @param [String] node_name
      #   name of the node as identified in Chef
      # @option options [String] :validator_path
      #   filepath to the validator used to bootstrap the node (required)
      # @option options [String] :bootstrap_proxy
      #   URL to a proxy server to bootstrap through (default: nil)
      # @option options [String] :encrypted_data_bag_secret_path
      #   filepath on your host machine to your organizations encrypted data bag secret (default: nil)
      # @option options [Hash] :hints
      #   a hash of Ohai hints to place on the bootstrapped node (default: Hash.new)
      # @option options [Hash] :attributes
      #   a hash of attributes to use in the first Chef run (default: Hash.new)
      # @option options [Array] :run_list
      #   an initial run list to bootstrap with (default: Array.new)
      # @option options [String] :chef_version
      #   version of Chef to install on the node (default: {Ridley::CHEF_VERSION})
      # @option options [String] :environment
      #   environment to join the node to (default: '_default')
      # @option options [Boolean] :sudo
      #   bootstrap with sudo (default: true)
      # @option options [String] :template
      #   bootstrap template to use (default: omnibus)
      def initialize(connection, node_name, options = {})
        @node_name                      = node_name
        @connection                     = connection
        @validator_path                 = options.fetch(:validator_path) {
          raise Errors::ArgumentError, "A path to a validator is required for bootstrapping"
        }
        @bootstrap_proxy                = options.fetch(:bootstrap_proxy, nil)
        @encrypted_data_bag_secret_path = options.fetch(:encrypted_data_bag_secret_path, nil)
        @hints                          = options.fetch(:hints, Hash.new)
        @attributes                     = options.fetch(:attributes, Hash.new)
        @run_list                       = options.fetch(:run_list, Array.new)
        @chef_version                   = options.fetch(:chef_version, Ridley::CHEF_VERSION)
        @environment                    = options.fetch(:environment, "_default")
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
        "chef-client -j /etc/chef/first-boot.json -E #{environment}"
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

      # The validation key to create a new client for the node
      #
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
