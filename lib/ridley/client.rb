module Ridley
  class Client
    class ConnectionSupervisor < ::Celluloid::SupervisionGroup
      def initialize(registry, options)
        super(registry)
        pool(Ridley::Connection, size: options[:pool_size], args: [
          options[:server_url],
          options[:client_name],
          options[:client_key],
          options.slice(*Ridley::Connection::VALID_OPTIONS)
        ], as: :connection_pool)
      end
    end

    class ResourcesSupervisor < ::Celluloid::SupervisionGroup
      def initialize(registry, connection_registry, options)
        super(registry)
        supervise_as :client_resource, Ridley::ClientResource, connection_registry
        supervise_as :cookbook_resource, Ridley::CookbookResource, connection_registry,
          options[:client_name], options[:client_key], options.slice(*Ridley::Connection::VALID_OPTIONS)
        supervise_as :data_bag_resource, Ridley::DataBagResource, connection_registry,
          options[:encrypted_data_bag_secret]
        supervise_as :environment_resource, Ridley::EnvironmentResource, connection_registry
        supervise_as :node_resource, Ridley::NodeResource, connection_registry, options
        supervise_as :role_resource, Ridley::RoleResource, connection_registry
        supervise_as :sandbox_resource, Ridley::SandboxResource, connection_registry,
          options[:client_name], options[:client_key], options.slice(*Ridley::Connection::VALID_OPTIONS)
        supervise_as :search_resource, Ridley::SearchResource, connection_registry
        supervise_as :user_resource, Ridley::UserResource, connection_registry
      end
    end

    class << self
      def open(options = {}, &block)
        client = new(options)
        yield client
      ensure
        client.terminate if client && client.alive?
      end

      # @raise [ArgumentError]
      #
      # @return [Boolean]
      def validate_options(options)
        missing = (REQUIRED_OPTIONS - options.keys)

        if missing.any?
          missing.collect! { |opt| "'#{opt}'" }
          raise ArgumentError, "Missing required option(s): #{missing.join(', ')}"
        end

        missing_values = options.slice(*REQUIRED_OPTIONS).select { |key, value| !value.present? }
        if missing_values.any?
          values = missing_values.keys.collect { |opt| "'#{opt}'" }
          raise ArgumentError, "Missing value for required option(s): '#{values.join(', ')}'"
        end
      end
    end

    REQUIRED_OPTIONS = [
      :server_url,
      :client_name,
      :client_key
    ].freeze

    extend Forwardable
    include Celluloid
    include Ridley::Logging

    finalizer :finalize_callback

    def_delegator :connection, :build_url
    def_delegator :connection, :scheme
    def_delegator :connection, :host
    def_delegator :connection, :port
    def_delegator :connection, :path_prefix
    def_delegator :connection, :url_prefix

    def_delegator :connection, :organization
    def_delegator :connection, :client_key
    def_delegator :connection, :client_key=
    def_delegator :connection, :client_name
    def_delegator :connection, :client_name=

    attr_reader :options

    attr_accessor :validator_client
    attr_accessor :validator_path
    attr_accessor :encrypted_data_bag_secret_path
    attr_accessor :chef_version

    # @option options [String] :server_url
    #   URL to the Chef API
    # @option options [String] :client_name
    #   name of the client used to authenticate with the Chef API
    # @option options [String] :client_key
    #   filepath to the client's private key used to authenticate with the Chef API
    # @option options [String] :validator_client (nil)
    # @option options [String] :validator_path (nil)
    # @option options [String] :encrypted_data_bag_secret_path (nil)
    # @option  options [String] :chef_version
    #   the version of Chef to use when bootstrapping
    # @option options [Hash] :params
    #   URI query unencoded key/value pairs
    # @option options [Hash] :headers
    #   unencoded HTTP header key/value pairs
    # @option options [Hash] :request
    #   request options
    # @option options [Hash] :ssl
    #   * :verify (Boolean) [true] set to false to disable SSL verification
    # @option options [URI, String, Hash] :proxy
    #   URI, String, or Hash of HTTP proxy options
    # @option options [Integer] :pool_size (4)
    #   size of the connection pool
    #
    # @raise [Errors::ClientKeyFileNotFoundOrInvalid] if the option for :client_key does not contain
    #   a file path pointing to a readable client key, or is a string containing a valid key
    def initialize(options = {})
      @options = options.reverse_merge(
        pool_size: 4
      ).deep_symbolize_keys
      self.class.validate_options(@options)

      @chef_version     = @options[:chef_version]
      @validator_client = @options[:validator_client]

      if @options[:validator_path]
        @validator_path = File.expand_path(@options[:validator_path])
      end

      @options[:encrypted_data_bag_secret] ||= begin
        if @options[:encrypted_data_bag_secret_path]
          @encrypted_data_bag_secret_path = File.expand_path(@options[:encrypted_data_bag_secret_path])
        end

        encrypted_data_bag_secret
      end

      unless verify_client_key(@options[:client_key])
        @options[:client_key] = File.expand_path(@options[:client_key])
        raise Errors::ClientKeyFileNotFoundOrInvalid, "client key is invalid or not found at: '#{@options[:client_key]}'" unless File.exist?(@options[:client_key]) && verify_client_key(::IO.read(@options[:client_key]))
      end

      @connection_registry   = Celluloid::Registry.new
      @resources_registry    = Celluloid::Registry.new
      @connection_supervisor = ConnectionSupervisor.new(@connection_registry, @options)
      @resources_supervisor  = ResourcesSupervisor.new(@resources_registry, @connection_registry, @options)
    end

    # @return [Ridley::ClientResource]
    def client
      @resources_registry[:client_resource]
    end

    # @return [Ridley::CookbookResource]
    def cookbook
      @resources_registry[:cookbook_resource]
    end

    # @return [Ridley::DataBagResource]
    def data_bag
      @resources_registry[:data_bag_resource]
    end

    # @return [Ridley::EnvironmentResource]
    def environment
      @resources_registry[:environment_resource]
    end

    # @return [Ridley::NodeResource]
    def node
      @resources_registry[:node_resource]
    end

    # @return [Ridley::RoleResource]
    def role
      @resources_registry[:role_resource]
    end

    # @return [Ridley::SandboxResource]
    def sandbox
      @resources_registry[:sandbox_resource]
    end

    # @return [Ridley::UserResource]
    def user
      @resources_registry[:user_resource]
    end

    # Perform a search the Chef Server
    #
    # @param [#to_sym, #to_s] index
    # @param [#to_s] query
    #
    # @option options [String] :sort
    #   a sort string such as 'name DESC'
    # @option options [Integer] :rows
    #   how many rows to return
    # @option options [Integer] :start
    #   the result number to start from
    #
    # @return [Array<ChefObject>, Hash]
    def search(index, query = nil, options = {})
      @resources_registry[:search_resource].run(index, query, @resources_registry, options)
    end

    # Return an array of all possible search indexes for the including connection
    #
    # @example
    #   ridley = Ridley.new(...)
    #   ridley.search_indexes #=>
    #     [:client, :environment, :node, :role, :"ridley-two", :"ridley-one"]
    #
    # @return [Array<Symbol, String>]
    def search_indexes
      @resources_registry[:search_resource].indexes
    end

    # Perform a partial search on the Chef Server. Partial objects or a smaller hash will be returned resulting
    # in a faster response for larger response sets. Specify the attributes you want returned with the
    # attributes parameter.
    #
    # @param [#to_sym, #to_s] index
    # @param [#to_s] query
    # @param [Array] attributes
    #   an array of strings in dotted hash notation representing the attributes to return
    #
    # @option options [String] :sort
    #   a sort string such as 'name DESC'
    # @option options [Integer] :rows
    #   how many rows to return
    # @option options [Integer] :start
    #   the result number to start from
    #
    # @example
    #   ridley = Ridley.new(...)
    #   ridley.partial_search(:node, "chef_environment:RESET", [ 'ipaddress', 'some.application.setting' ]) #=>
    #     [
    #       #<Ridley::NodeObject: chef_id:"reset.riotgames.com" normal:
    #         { "ipaddress" => "192.168.1.1", "some" => { "application" => { "setting" => "value" } } } ...>
    #     ]
    #
    # @return [Array<ChefObject>, Hash]
    def partial_search(index, query = nil, attributes = [], options = {})
      @resources_registry[:search_resource].partial(index, query, Array(attributes), @resources_registry, options)
    end

    # The encrypted data bag secret for this connection.
    #
    # @raise [Ridley::Errors::EncryptedDataBagSecretNotFound]
    #
    # @return [String, nil]
    def encrypted_data_bag_secret
      return nil if encrypted_data_bag_secret_path.nil?

      ::IO.read(encrypted_data_bag_secret_path).chomp
    rescue Errno::ENOENT => e
      raise Errors::EncryptedDataBagSecretNotFound, "Encrypted data bag secret provided but not found at '#{encrypted_data_bag_secret_path}'"
    end

    def server_url
      self.url_prefix.to_s
    end

    private

      def verify_client_key(key)
        OpenSSL::PKey::RSA.new(key)
        true
      rescue
        false
      end

      def connection
        @connection_registry[:connection_pool]
      end

      def finalize_callback
        @connection_supervisor.async.terminate if @connection_supervisor
        @resources_supervisor.async.terminate if @resources_supervisor
      end
  end
end
