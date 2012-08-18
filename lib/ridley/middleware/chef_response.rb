module Ridley
  module Middleware
    # @author Jamie Winsor <jamie@vialstudios.com>
    class ChefResponse < Faraday::Response::Middleware
      def on_complete(env)
        Ridley.log.debug(env)

        env[:body] = parse(env[:body])
        
        unless success?(env)
          raise Errors::HTTPError.fabricate(env)
        end
      end

      private

        def parse(body)
          MultiJson.load(body, symbolize_keys: true)
        end

        def success?(env)
          (200..210).to_a.index(env[:status].to_i) ? true : false
        end
    end
  end
end
