require 'erubis'

module Ridley
  module BootstrapBinding
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
          attributes: Hash.new,
          run_list: Array.new,
          environment: "_default",
          sudo: true,
          hints: Hash.new
        }
      end
    end

    attr_reader :template_file
    attr_reader :bootstrap_proxy
    attr_reader :chef_version
    attr_reader :default_options
    attr_reader :validator_path
    attr_reader :encrypted_data_bag_secret_path
    attr_reader :server_url
    attr_reader :validator_client
    attr_reader :node_name
    attr_reader :attributes
    attr_reader :run_list
    attr_reader :environment

    # @return [Pathname]
    def templates_path
      Ridley.root.join('bootstrappers')
    end

    # @return [String]
    def first_boot
      MultiJson.encode attributes.merge(run_list: run_list)
    end

    # @raise [Ridley::Errors::EncryptedDataBagSecretNotFound]
    #
    # @return [String, nil]
    def encrypted_data_bag_secret
      return unless encrypted_data_bag_secret_path

      IO.read(encrypted_data_bag_secret_path).chomp
    rescue Errno::ENOENT
      raise Errors::EncryptedDataBagSecretNotFound, "Error bootstrapping: Encrypted data bag secret provided but not found at '#{encrypted_data_bag_secret_path}'"
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

    # @return [Erubis::Eruby]
    def template
      Erubis::Eruby.new(IO.read(template_file).chomp)
    end

  end
end