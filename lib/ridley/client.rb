module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  #
  # @example
  #   connection = Ridley::Client.new
  #   connection.role.all
  #
  #   connection.role.find("reset") => Ridley::RoleResource.find(connection, "reset")
  #
  # @example instantiating new resources
  #   connection = Ridley::Connection.new
  #   connection.role.new(name: "hello") => <#Ridley::RoleResource: @name="hello">
  #
  #   New instances of resources can be instantiated by calling new on the Ridley::Context. These messages
  #   will be send to the Chef resource's class in Ridley and can be treated as a normal Ruby object. Each
  #   instantiated object will have the connection information contained within so you can do things like
  #   save a role after changing it's attributes.
  #
  #   r = connection.role.new(name: "new-role")
  #   r.name => "new-role"
  #   r.name = "other-name"
  #   r.save
  #
  #   connection.role.find("new-role") => <#Ridley::RoleResource: @name="new-role">
  class Client
    class ConnectionSupervisor < ::Celluloid::SupervisionGroup
      task_class TaskThread

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
      task_class TaskThread

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

    task_class TaskThread

    finalizer do
      @connection_supervisor.terminate if @connection_supervisor && @connection_supervisor.alive?
      @resources_supervisor.terminate if @resources_supervisor && @resources_supervisor.alive?
    end

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
    attr_accessor :ssh
    attr_accessor :winrm
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
    # @option options [Hash] :ssh (Hash.new)
    #   * :user (String) a shell user that will login to each node and perform the bootstrap command on (required)
    #   * :password (String) the password for the shell user that will perform the bootstrap
    #   * :keys (Array, String) an array of keys (or a single key) to authenticate the ssh user with instead of a password
    #   * :timeout (Float) [5.0] timeout value for SSH bootstrap
    #   * :sudo (Boolean) [true] bootstrap with sudo
    # @option options [Hash] :winrm (Hash.new)
    #   * :user (String) a user that will login to each node and perform the bootstrap command on (required)
    #   * :password (String) the password for the user that will perform the bootstrap
    #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
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
    # @raise [Errors::ClientKeyFileNotFound] if the option for :client_key does not contain
    #   a file path pointing to a readable client key
    def initialize(options = {})
      @options = options.reverse_merge(
        ssh: Hash.new,
        winrm: Hash.new,
        pool_size: 4
      ).deep_symbolize_keys
      self.class.validate_options(@options)

      @ssh              = @options[:ssh]
      @winrm            = @options[:winrm]
      @chef_version     = @options[:chef_version]
      @validator_client = @options[:validator_client]

      @options[:client_key] = File.expand_path(@options[:client_key])

      if @options[:validator_path]
        @validator_path = File.expand_path(@options[:validator_path])
      end

      if @options[:encrypted_data_bag_secret_path]
        @encrypted_data_bag_secret_path = File.expand_path(@options[:encrypted_data_bag_secret_path])
      end

      @options[:encrypted_data_bag_secret] = encrypted_data_bag_secret

      unless @options[:client_key].present? && File.exist?(@options[:client_key])
        raise Errors::ClientKeyFileNotFound, "client key not found at: '#{@options[:client_key]}'"
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

    # Perform a search the Chef Server
    #
    # @param [#to_sym, #to_s] index
    # @param [#to_s] query_string
    #
    # @option options [String] :sort
    #   a sort string such as 'name DESC'
    # @option options [Integer] :rows
    #   how many rows to return
    # @option options [Integer] :start
    #   the result number to start from
    #
    # @return [Hash]
    def search(index, query = nil, options = {})
      @resources_registry[:search_resource].run(index, query, @resources_registry, options)
    end

    # Return the array of all possible search indexes for the including connection
    #
    # @example
    #   conn = Ridley.new(...)
    #   conn.search_indexes =>
    #     [:client, :environment, :node, :role, :"ridley-two", :"ridley-one"]
    #
    # @return [Array<Symbol, String>]
    def search_indexes
      @resources_registry[:search_resource].indexes
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

      def connection
        @connection_registry[:connection_pool]
      end
  end
end
