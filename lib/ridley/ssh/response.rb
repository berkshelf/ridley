module Ridley
  class SSH
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Response
      attr_reader :stdout
      attr_reader :stderr
      attr_reader :exit_code
      attr_reader :exit_signal
      
      def initialize(options = {})
        @stdout      = options[:stdout] || String.new
        @stderr      = options[:stderr] || String.new
        @exit_code   = options[:exit_code] || -1
        @exit_signal = options[:exit_signal] || nil
      end

      # Return true if the response was not successful
      #
      # @return [Boolean]
      def error?
        self.exit_code != 0
      end
    end
  end
end
