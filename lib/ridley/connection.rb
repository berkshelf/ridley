module Ridley
  class Connection
    class << self
      def start(server_url, client_name, client_key, &block)
        new(server_url, client_name, client_key).start(&block)
      end
      alias_method :open, :start
    end

    extend Forwardable
    include Environment::DSL

    cattr_accessor :active

    attr_reader :client_name
    attr_reader :client_key

    def_delegator :server_uri, :scheme
    def_delegator :server_uri, :host
    def_delegator :server_uri, :port
    def_delegator :server_uri, :path
    def_delegator :server_uri, :query

    def initialize(server_url, client_name, client_key)
      @server_uri = Addressable::URI.parse(server_url)
      @client_name = client_name
      @client_key = client_key

      @conn = Faraday.new(server_url) do |c|
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
      evaluate(&block)
      self.class.active = original_conn
    end
    alias_method :open, :start

    def get(path)
      conn.run_request(:get, server_uri.join(path), nil, Hash.new)
    end

    def put(path, body)
      conn.run_request(:put, server_uri.join(path), body, Hash.new)
    end

    def post(path, body)
      conn.run_request(:post, server_uri.join(path), body, Hash.new)
    end

    def delete(path)
      conn.run_request(:delete, server_uri.join(path), nil, Hash.new)
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
  end
end
