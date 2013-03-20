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
  class Client < Celluloid::SupervisionGroup
    class << self
      def open(options = {}, &block)
        cli = new(options)
        cli.evaluate(&block)
      ensure
        cli.terminate if cli && cli.alive?
      end

      # @raise [ArgumentError]
      #
      # @return [Boolean]
      def validate_options(options)
        missing = (REQUIRED_OPTIONS - options.keys)

        unless missing.empty?
          missing.collect! { |opt| "'#{opt}'" }
          raise ArgumentError, "Missing required option(s): #{missing.join(', ')}"
        end

        missing_values = options.slice(*REQUIRED_OPTIONS).select { |key, value| !value.present? }
        unless missing_values.empty?
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
    include Ridley::Logging

    def_delegator :connection, :build_url
    def_delegator :connection, :scheme
    def_delegator :connection, :host
    def_delegator :connection, :port
    def_delegator :connection, :path_prefix
    def_delegator :connection, :url_prefix

    def_delegator :connection, :client_key
    def_delegator :connection, :client_key=
    def_delegator :connection, :client_name
    def_delegator :connection, :client_name=

    attr_reader :options

    attr_accessor :validator_client
    attr_accessor :validator_path
    attr_accessor :encrypted_data_bag_secret_path
    attr_accessor :ssh

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
    #
    # @raise [Errors::ClientKeyFileNotFound] if the option for :client_key does not contain
    #   a file path pointing to a readable client key
    def initialize(options = {})
      log.info { "Ridley starting..." }
      super()

      @options = options.reverse_merge(
        ssh: Hash.new
      ).deep_symbolize_keys
      self.class.validate_options(@options)

      @ssh              = @options[:ssh]
      @validator_client = @options[:validator_client]

      @options[:client_key] = File.expand_path(@options[:client_key])

      if @options[:validator_path]
        @validator_path = File.expand_path(@options[:validator_path])
      end

      if @options[:encrypted_data_bag_secret_path]
        @encrypted_data_bag_secret_path = File.expand_path(@options[:encrypted_data_bag_secret_path])
      end

      unless @options[:client_key].present? && File.exist?(@options[:client_key])
        raise Errors::ClientKeyFileNotFound, "client key not found at: '#{@options[:client_key]}'"
      end

      pool(Ridley::Connection, size: 4, args: [
        @options[:server_url],
        @options[:client_name],
        @options[:client_key],
        @options.slice(*Connection::VALID_OPTIONS)
      ], as: :connection_pool)
    end

    # @return [Ridley::ChainLink]
    def client
      ChainLink.new(Actor.current, Ridley::ClientResource)
    end

    # @return [Ridley::ChainLink]
    def cookbook
      ChainLink.new(Actor.current, Ridley::CookbookResource)
    end

    # @return [Ridley::ChainLink]
    def data_bag
      ChainLink.new(Actor.current, Ridley::DataBagResource)
    end

    # @return [Ridley::ChainLink]
    def environment
      ChainLink.new(Actor.current, Ridley::EnvironmentResource)
    end

    # @return [Ridley::ChainLink]
    def node
      ChainLink.new(Actor.current, Ridley::NodeResource)
    end

    # @return [Ridley::ChainLink]
    def role
      ChainLink.new(Actor.current, Ridley::RoleResource)
    end

    # @return [Ridley::ChainLink]
    def sandbox
      ChainLink.new(Actor.current, Ridley::SandboxResource)
    end

    # Creates an runs a new Ridley::Search
    #
    # @see Ridley::Search#run
    #
    # @param [String, Symbol] index
    # @param [String, nil] query
    #
    # @option options [String] :sort
    # @option options [Integer] :rows
    # @option options [Integer] :start
    #
    # @return [Hash]
    def search(index, query = nil, options = {})
      Ridley::Search.new(Actor.current, index, query, options).run
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
      Ridley::Search.indexes(Actor.current)
    end

    # The encrypted data bag secret for this connection.
    #
    # @raise [Ridley::Errors::EncryptedDataBagSecretNotFound]
    #
    # @return [String, nil]
    def encrypted_data_bag_secret
      return nil if encrypted_data_bag_secret_path.nil?

      IO.read(encrypted_data_bag_secret_path).chomp
    rescue Errno::ENOENT => e
      raise Errors::EncryptedDataBagSecretNotFound, "Encrypted data bag secret provided but not found at '#{encrypted_data_bag_secret_path}'"
    end

    def server_url
      self.url_prefix.to_s
    end

    def evaluate(&block)
      unless block_given?
        raise LocalJumpError, "no block given (yield)"
      end

      @self_before_instance_eval = eval("self", block.binding)
      instance_eval(&block)
    end
    alias_method :sync, :evaluate

    def finalize
      connection.terminate if connection && connection.alive?
    end

    def connection
      @registry[:connection_pool]
    end

    private

      def method_missing(method, *args, &block)
        if block_given?
          @self_before_instance_eval ||= eval("self", block.binding)
        end

        if @self_before_instance_eval.nil?
          super
        end

        @self_before_instance_eval.send(method, *args, &block)
      end
  end
end
