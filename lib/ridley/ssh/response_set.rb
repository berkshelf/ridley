module Ridley
  class SSH
    # @author Jamie Winsor <jamie@vialstudios.com>
    class ResponseSet
      extend Forwardable
      include Enumerable

      attr_reader :failures
      attr_reader :successes

      def_delegator :responses, :each

      def initialize(responses = Array.new)
        @failures  = Array.new
        @successes = Array.new

        add_response Array(responses)
      end

      # @param [SSH::Response, Array<SSH::Response>] response
      #
      # @return [Array<SSH::Response>]
      def add_response(response)
        if response.is_a?(Array)
          until response.empty?
            add_response(response.pop)
          end
          return responses
        end

        response.error? ? add_failure(response) : add_success(response)
        responses
      end
      alias_method :<<, :add_response

      def responses
        successes + failures
      end

      # Return true if the response set contains any errors
      #
      # @return [Boolean]
      def has_errors?
        self.failures.any?
      end

      private

        # @param [SSH::Response] response
        def add_failure(response)
          self.failures << response
        end

        # @param [SSH::Response] response
        def add_success(response)
          self.successes << response
        end
    end
  end
end
