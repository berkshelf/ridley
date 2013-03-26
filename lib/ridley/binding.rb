require 'erubis'

module Ridley
  # @author Kyle Allan <kallan@riotgames.com>
  class Binding
    class << self
      def validate_options(options = {})
        if options[:server_url].nil?
          raise Errors::ArgumentError, "A server_url is required for bootstrapping"
        end

        if options[:validator_path].nil?
          raise Errors::ArgumentError, "A path to a validator is required for bootstrapping"
        end
      end
    end

    attr_reader :default_options

    # A hash of default options to be used in the Context initializer
    #
    # @return [Hash]
    def default_options
      @default_options ||= {
        validator_client: "chef-validator",
        hints: Hash.new,
        attributes: Hash.new,
        run_list: Array.new,
        environment: "_default",
        sudo: true,
        template: default_template
      }
    end

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
      return nil if encrypted_data_bag_secret_path.nil?

      IO.read(encrypted_data_bag_secret_path).chomp
    rescue Errno::ENOENT => encrypted_data_bag_secret
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
