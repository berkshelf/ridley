require 'mixlib/authentication/signedheaderauth'

module Ridley
  module Middleware
    # @author Jamie Winsor <jamie@vialstudios.com>
    class ChefAuth < Faraday::Middleware
      class << self
        include Mixlib::Authentication

        # Generate authentication headers for a request to a Chef Server
        #
        # @param [String] client_name
        # @param [String] client_key
        #
        # @see {#signing_object} for options
        def authentication_headers(client_name, client_key, options = {})
          rsa_key = OpenSSL::PKey::RSA.new(File.read(client_key))
          signing_object(client_name, options).sign(rsa_key)
        end

        # Create a signing object for a Request to a Chef Server
        #
        # @param [String] client_name
        #
        # @option options [String] :http_method
        # @option options [String] :host
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
          options[:user_id] = client_name

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
          host: env[:url].host,
          path: env[:url].path,
          body: env[:body]
        }
        authentication_headers = self.class.authentication_headers(client_name, client_key, signing_options)

        env[:request_headers] = default_headers.merge(env[:request_headers]).merge(authentication_headers)
        env[:request_headers] = env[:request_headers].merge('Content-Length' => env[:body].bytesize.to_s) if env[:body]

        log.debug { "Performing Authenticated Chef Request: "}
        log.debug { env }

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
