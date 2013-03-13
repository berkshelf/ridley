module Ridley
  class SSH
    # @author Jamie Winsor <reset@riotgames.com>
    class ResponseSet
      class << self
        # Merges the responses of the other ResponseSet with the target ResponseSet
        # and returns the mutated target
        #
        # @param [SSH::ResponseSet] target
        # @param [SSH::ResponseSet] other
        #
        # @return [SSH::ResponseSet]
        def merge!(target, other)
          if other.is_a?(self)
            target.add_response(other.responses)
          end

          target
        end
      end

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

      # Merges the responses of another ResponseSet with self and returns
      # a new instance of ResponseSet
      #
      # @param [Ridley::SSH::ResponseSet] other
      #
      # @return [Ridley::SSH::ResponseSet]
      def merge(other)
        target = self.class.new(self.responses) # Why the fuck can't I use #dup here?
        self.class.merge!(target, other)
      end

      # Merges the respones of another ResponseSet with self and returns
      # mutated self
      #
      # @param [Ridley::SSH::ResponseSet] other
      #
      # @return [self]
      def merge!(other)
        self.class.merge!(self, other)
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
