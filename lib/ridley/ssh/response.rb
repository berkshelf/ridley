module Ridley
  class SSH
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Response < Struct.new(:stdout, :stderr, :exit_code, :exit_signal)
      # Return true if the response was not successful
      #
      # @return [Boolean]
      def error?
        self.exit_code != 0
      end
    end
  end
end
