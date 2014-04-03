module Ridley
  module Middleware
    class ChefResponse < Faraday::Response::Middleware
      class << self
        # Determines if a response from the Chef server was successful
        #
        # @param [Hash] env
        #   a faraday request env
        #
        # @return [Boolean]
        def success?(env)
          (200..210).to_a.index(env[:status].to_i) ? true : false
        end
      end

      include Ridley::Logging

      def on_complete(env)
        log.debug { "==> handling Chef response" }
        log.debug { "request env: #{env}" }

        unless self.class.success?(env)
          log.debug { "** error encounted in Chef response" }
          raise Errors::HTTPError.fabricate(env)
        end
      end
    end
  end
end

Faraday::Response.register_middleware chef_response: Ridley::Middleware::ChefResponse
