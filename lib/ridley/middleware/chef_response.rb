module Ridley
  module Middleware
    # @author Jamie Winsor <jamie@vialstudios.com>
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

      def on_complete(env)
        Ridley.log.debug("Handling Chef Response")
        Ridley.log.debug(env)
        
        unless self.class.success?(env)
          Ridley.log.debug("Error encounted in Chef Response")
          raise Errors::HTTPError.fabricate(env)
        end
      end
    end
  end
end
