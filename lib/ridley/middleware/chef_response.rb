module Ridley
  module Middleware
    class ChefResponse < Faraday::Response::Middleware
      def on_complete(env)
        Ridley.log.debug(env)
        
        env[:body] = parse(env[:body])

        unless [200, 201].index(env[:status].to_i)
          raise Errors::HTTPError.fabricate(env)
        end
      end

      private

        def parse(body)
          MultiJson.load(body, symbolize_keys: true)
        end
    end
  end
end
