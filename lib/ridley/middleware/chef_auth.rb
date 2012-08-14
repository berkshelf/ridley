require 'mixlib/authentication/signedheaderauth'

module Ridley
  module Middleware
    class ChefAuth < Faraday::Middleware
      attr_reader :client_name
      attr_reader :client_key

      def initialize(app, client_name, client_key)
        super(app)
        @client_name = client_name
        @client_key = OpenSSL::PKey::RSA.new(File.read(client_key))
      end

      def call(env)
        sign_obj = Mixlib::Authentication::SignedHeaderAuth.signing_object(
          http_method: env[:method],
          host: env[:url].host,
          path: env[:url].path,
          body: env[:body] || '',
          timestamp: Time.now.utc.iso8601,
          user_id: client_name
        )
        authentication_headers = sign_obj.sign(client_key)
        env[:request_headers] = env[:request_headers].merge(authentication_headers).merge(default_headers)
        env[:request_headers] = env[:request_headers].merge('Content-Length' => env[:body].bytesize.to_s) if env[:body]

        Ridley.log.debug(env)

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
