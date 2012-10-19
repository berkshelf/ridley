module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Connection
    class << self
      def sync(options, &block)
        new(options).sync(&block)
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
      end
    end

    extend Forwardable
    include Ridley::DSL

    attr_reader :client_name
    attr_reader :client_key
    attr_reader :organization

    attr_accessor :thread_count

    def_delegator :conn, :build_url
    def_delegator :conn, :scheme
    def_delegator :conn, :host
    def_delegator :conn, :port
    def_delegator :conn, :path_prefix

    def_delegator :conn, :url_prefix=

    def_delegator :conn, :get
    def_delegator :conn, :put
    def_delegator :conn, :post
    def_delegator :conn, :delete
    def_delegator :conn, :head

    def_delegator :conn, :in_parallel

    REQUIRED_OPTIONS = [
      :server_url,
      :client_name,
      :client_key
    ]

    DEFAULT_THREAD_COUNT = 8

    # @option options [String] :server_url
    #   URL to the Chef API
    # @option options [String] :client_name
    #   name of the client used to authenticate with the Chef API
    # @option options [String] :client_key
    #   filepath to the client's private key used to authenticate with
    #   the Chef API
    # @option options [String] :organization
    #   the Organization to connect to. This is only used if you are connecting to
    #   private Chef or hosted Chef
    # @option options [Integer] :thread_count
    # @option options [Hash] :params
    #   URI query unencoded key/value pairs
    # @option options [Hash] :headers
    #   unencoded HTTP header key/value pairs
    # @option options [Hash] :request
    #   request options
    # @option options [Hash] :ssl
    #   SSL options
    # @option options [URI, String, Hash] :proxy
    #   URI, String, or Hash of HTTP proxy options
    def initialize(options = {})
      self.class.validate_options(options)

      @client_name  = options.fetch(:client_name)
      @client_key   = options.fetch(:client_key)
      @organization = options.fetch(:organization, nil)
      @thread_count = options.fetch(:thread_count, DEFAULT_THREAD_COUNT)

      unless @client_key.present? && File.exist?(@client_key)
        raise Errors::ClientKeyFileNotFound, "client key not found at: '#{@client_key}'"
      end

      faraday_options = options.slice(:params, :headers, :request, :ssl, :proxy)
      uri_hash = Addressable::URI.parse(options[:server_url]).to_hash.slice(:scheme, :host, :port)

      unless uri_hash[:port]
        uri_hash[:port] = (uri_hash[:scheme] == "https" ? 443 : 80)
      end

      if org_match = options[:server_url].match(/.*\/organizations\/(.*)/)
        @organization ||= org_match[1]
      end

      unless organization.nil?
        uri_hash[:path] = "/organizations/#{organization}"
      end

      server_uri = Addressable::URI.new(uri_hash)

      @conn = Faraday.new(server_uri, faraday_options) do |c|
        c.request :chef_auth, client_name, client_key
        c.response :chef_response
        c.response :json

        c.adapter Faraday.default_adapter
      end
    end

    def sync(&block)
      unless block
        raise Errors::InternalError, "A block must be given to synchronously process requests."
      end

      evaluate(&block)
    end

    # @return [Symbol]
    def api_type
      organization.nil? ? :foss : :hosted
    end

    # @return [Boolean]
    def hosted?
      api_type == :hosted
    end

    # @return [Boolean]
    def foss?
      api_type == :foss
    end

    private

      attr_reader :conn

      def evaluate(&block)
        @self_before_instance_eval = eval("self", block.binding)
        instance_eval(&block)
      end

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
