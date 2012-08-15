module Ridley
  class Connection
    class << self
      def start(options, &block)
        new(options).start(&block)
      end
      alias_method :open, :start
    end

    extend Forwardable
    include Ridley::DSL

    @@thread_count = 8

    cattr_accessor :active
    cattr_accessor :thread_count

    attr_reader :client_name
    attr_reader :client_key
    attr_reader :organization

    def_delegator :conn, :build_url
    def_delegator :conn, :scheme
    def_delegator :conn, :host
    def_delegator :conn, :port
    def_delegator :conn, :path_prefix

    REQUIRED_OPTIONS = [
      :server_url,
      :client_name,
      :client_key
    ]

    # @option options [String] :server_url
    # @option options [String] :client_name
    # @option options [String] :client_key
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
      validate_options(options)

      @client_name  = options[:client_name]
      @client_key   = options[:client_key]
      @organization = options[:organization]

      faraday_options = options.slice(:params, :headers, :request, :ssl, :proxy)
      uri_hash = Addressable::URI.parse(options[:server_url]).to_hash.slice(:scheme, :host, :port)

      unless uri_hash[:port]
        uri_hash[:port] = (uri_hash[:scheme] == "https" ? 443 : 80)
      end

      if organization
        uri_hash[:path] = "/organizations/#{organization}"
      end

      server_uri = Addressable::URI.new(uri_hash)

      @conn = Faraday.new(server_uri, faraday_options) do |c|
        c.request :chef_auth, client_name, client_key
        c.response :chef_response

        c.adapter Faraday.default_adapter
      end
    end

    def start(&block)
      unless block
        raise Errors::InternalError, "A block must be given to start a connection."
      end

      original_conn = self.class.active
      self.class.active = self
      result = evaluate(&block)
      self.class.active = original_conn

      result
    end
    alias_method :open, :start

    def get(path)
      conn.run_request(:get, path, nil, Hash.new)
    end

    def put(path, body)
      conn.run_request(:put, path, body, Hash.new)
    end

    def post(path, body)
      conn.run_request(:post, path, body, Hash.new)
    end

    def delete(path)
      conn.run_request(:delete, path, nil, Hash.new)
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
        @self_before_instance_eval.send(method, *args, &block)
      end

      def validate_options(options)
        missing = REQUIRED_OPTIONS - options.keys
        unless missing.empty?
          missing.collect! { |opt| "'#{opt}'" }
          raise ArgumentError, "missing required option(s): #{missing.join(', ')}"
        end
      end
  end
end
