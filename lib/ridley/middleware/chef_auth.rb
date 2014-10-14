require 'mixlib/authentication/signedheaderauth'

module Ridley
  module Middleware
    class ChefAuth < Faraday::Middleware
      class << self
        include Mixlib::Authentication

        # Generate authentication headers for a request to a Chef Server
        #
        # @param [String] client_name
        # @param [String] client_key
        #   the path OR actual client key
        #
        # @option options [String] :host
        #
        # @see {#signing_object} for options
        def authentication_headers(client_name, client_key, options = {})
          contents = File.exists?(client_key) ? File.read(client_key) : client_key.to_s
          rsa_key = OpenSSL::PKey::RSA.new(contents)

          headers = signing_object(client_name, options).sign(rsa_key).merge(host: options[:host])
          headers.inject({}) { |memo, kv| memo["#{kv[0].to_s.upcase}"] = kv[1];memo }
        end

        # Create a signing object for a Request to a Chef Server
        #
        # @param [String] client_name
        #
        # @option options [String] :http_method
        # @option options [String] :path
        # @option options [String] :body
        # @option options [Time] :timestamp
        #
        # @return [SigningObject]
        def signing_object(client_name, options = {})
          options = options.reverse_merge(
            body: String.new,
            timestamp: Time.now.utc.iso8601
          )
          options[:user_id]       = client_name
          options[:proto_version] = "1.0"

          SignedHeaderAuth.signing_object(options)
        end
      end

      include Ridley::Logging

      attr_reader :client_name
      attr_reader :client_key

      def initialize(app, client_name, client_key)
        super(app)
        @client_name = client_name
        @client_key  = client_key
      end

      def call(env)
        signing_options = {
          http_method: env[:method],
          host: "#{env[:url].host}:#{env[:url].port}",
          path: env[:url].path,
          body: env[:body] || ''
        }
        authentication_headers = self.class.authentication_headers(client_name, client_key, signing_options)

        env[:request_headers] = default_headers.merge(env[:request_headers]).merge(authentication_headers)
        env[:request_headers] = env[:request_headers].merge('Content-Length' => env[:body].bytesize.to_s) if env[:body]

        log.debug { "==> performing authenticated Chef request as '#{client_name}'"}
        log.debug { "request env: #{env}"}

        @app.call(env)
      end

      private

        def default_headers
          {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
            'X-Chef-Version' => Ridley::CHEF_VERSION
          }
        end
    end
  end
end

Faraday::Request.register_middleware chef_auth: Ridley::Middleware::ChefAuth
