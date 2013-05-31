require 'erubis'

module Ridley
  module BootstrapContext
    class Base
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

      attr_reader :template_file
      attr_reader :bootstrap_proxy
      attr_reader :chef_version
      attr_reader :validator_path
      attr_reader :encrypted_data_bag_secret
      attr_reader :server_url
      attr_reader :validator_client
      attr_reader :node_name
      attr_reader :attributes
      attr_reader :run_list
      attr_reader :environment
      attr_reader :hints

      def initialize(options = {})
        options = options.reverse_merge(
          validator_client: "chef-validator",
          attributes: Hash.new,
          run_list: Array.new,
          environment: "_default",
          sudo: true,
          hints: Hash.new,
          chef_version: "latest"
        )
        options[:template] ||= default_template
        self.class.validate_options(options)

        @template_file             = options[:template]
        @bootstrap_proxy           = options[:bootstrap_proxy]
        @chef_version              = options[:chef_version]
        @sudo                      = options[:sudo]
        @validator_path            = options[:validator_path]
        @encrypted_data_bag_secret = options[:encrypted_data_bag_secret]
        @hints                     = options[:hints]
        @server_url                = options[:server_url]
        @validator_client          = options[:validator_client]
        @node_name                 = options[:node_name]
        @attributes                = options[:attributes]
        @run_list                  = options[:run_list]
        @environment               = options[:environment]
      end

      # @return [String]
      def bootstrap_command
        raise RuntimeError, "abstract function: must be implemented on includer"
      end

      # @return [String]
      def default_template
        raise RuntimeError, "abstract function: must be implemented on includer"
      end

      # @return [Pathname]
      def templates_path
        Ridley.root.join('bootstrappers')
      end

      # @return [String]
      def first_boot
        JSON.fast_generate(attributes.merge(run_list: run_list))
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
end

Dir["#{File.dirname(__FILE__)}/bootstrap_context/*.rb"].sort.each do |path|
  require_relative "bootstrap_context/#{File.basename(path, '.rb')}"
end
