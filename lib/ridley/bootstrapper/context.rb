require 'erubis'

module Ridley
  class Bootstrapper
    # @author Jamie Winsor <reset@riotgames.com>
    class Context
      class << self
        def validate_options(options = {})
          if options[:server_url].nil?
            raise Errors::ArgumentError, "A server_url is required for bootstrapping"
          end

          if options[:validator_path].nil?
            raise Errors::ArgumentError, "A path to a validator is required for bootstrapping"
          end
        end

        # A hash of default options to be used in the Context initializer
        #
        # @return [Hash]
        def default_options
          @default_options ||= {
            validator_client: "chef-validator",
            hints: Hash.new,
            attributes: Hash.new,
            run_list: Array.new,
            chef_version: Ridley::CHEF_VERSION,
            environment: "_default",
            sudo: true,
            template: Bootstrapper.default_template
          }
        end
      end

      # @return [String]
      attr_reader :host
      # @return [String]
      attr_reader :node_name
      # @return [String]
      attr_reader :server_url
      # @return [String]
      attr_reader :validator_client
      # @return [String]
      attr_reader :validator_path
      # @return [String]
      attr_reader :bootstrap_proxy
      # @return [Hash]
      attr_reader :hints
      # @return [String]
      attr_reader :chef_version
      # @return [String]
      attr_reader :environment

      # @param [String] host
      #   name of the node as identified in Chef
      # @option options [String] :validator_path
      #   filepath to the validator used to bootstrap the node (required)
      # @option options [String] :node_name
      # @option options [String] :server_url
      # @option options [String] :validator_client
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
      def initialize(host, options = {})
        options = self.class.default_options.merge(options)
        self.class.validate_options(options)

        @host                           = host
        @server_url                     = options[:server_url]
        @validator_path                 = options[:validator_path]
        @node_name                      = options[:node_name]
        @validator_client               = options[:validator_client]
        @bootstrap_proxy                = options[:bootstrap_proxy]
        @encrypted_data_bag_secret_path = options[:encrypted_data_bag_secret_path]
        @hints                          = options[:hints]
        @attributes                     = options[:attributes]
        @run_list                       = options[:run_list]
        @chef_version                   = options[:chef_version]
        @environment                    = options[:environment]
        @sudo                           = options[:sudo]
        @template_file                  = options[:template]
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
      def clean_command
        "rm /etc/chef/first-boot.json; rm /etc/chef/validation.pem"
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
chef_server_url  "#{server_url}"
validation_client_name "#{validator_client}"
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
        MultiJson.encode attributes.merge(run_list: run_list)
      end

      # The validation key to create a new client for the node
      #
      # @raise [Ridley::Errors::ValidatorNotFound]
      #
      # @return [String]
      def validation_key
        IO.read(File.expand_path(validator_path)).chomp
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
        raise Errors::EncryptedDataBagSecretNotFound, "Error bootstrapping: Encrypted data bag secret provided but not found at '#{encrypted_data_bag_secret_path}'"
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
