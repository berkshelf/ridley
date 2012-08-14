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

    cattr_accessor :active

    attr_reader :client_name
    attr_reader :client_key
    attr_reader :organization

    def_delegator :server_uri, :scheme
    def_delegator :server_uri, :host
    def_delegator :server_uri, :port
    def_delegator :server_uri, :path

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
      parse_options(options)
      faraday_options = options.slice(:params, :headers, :request, :ssl, :proxy)

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

    private

      attr_reader :server_uri
      attr_reader :conn

      def evaluate(&block)
        @self_before_instance_eval = eval("self", block.binding)
        instance_eval(&block)
      end

      def method_missing(method, *args, &block)
        @self_before_instance_eval.send(method, *args, &block)
      end

      def parse_options(options)
        missing = REQUIRED_OPTIONS - options.keys
        unless missing.empty?
          missing.collect! { |opt| "'#{opt}'" }
          raise ArgumentError, "missing required option(s): #{missing.join(', ')}"
        end

        @client_name = options[:client_name]
        @client_key = options[:client_key]
        @organization = options[:organization]

        uri_hash = Addressable::URI.parse(options[:server_url]).to_hash.slice(:scheme, :host, :port)

        unless uri_hash[:port]
          uri_hash[:port] = (uri_hash[:scheme] == "https" ? 443 : 80)
        end

        if organization
          uri_hash[:path] = "/organizations/#{organization}"
        end

        @server_uri = Addressable::URI.new(uri_hash)
      end
  end
end
