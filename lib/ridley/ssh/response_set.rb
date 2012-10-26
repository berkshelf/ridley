module Ridley
  class SSH
    # @author Jamie Winsor <jamie@vialstudios.com>
    class ResponseSet
      # @return [Array<SSH::Response>]
      attr_reader :oks
      # @return [Array<SSH::Response>]
      attr_reader :errors

      def initialize
        @oks = Array.new
        @errors = Array.new
      end

      # Add an "OK" response to the ResponseSet
      #
      # @param [SSH::Response] response
      def add_ok(response)
        self.oks << response
      end

      # Add an "Error" response to the ResponseSet
      #
      # @param [SSH::Response] response
      def add_error(response)
        self.errors << response
      end

      # Return true if the response set contains any errors
      #
      # @return [Boolean]
      def has_errors?
        self.errors.any?
      end

      # Return one of the responses
      #
      # @return [SSH::Response]
      def first
        (self.oks + self.errors).first
      end

      # Returns how many responses are in the set
      #
      # @return [Integer]
      def length
        self.oks.length + self.errors.length
      end
    end
  end
end
