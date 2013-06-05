module Ridley
  module HostConnector
    class Response
      attr_reader :host

      attr_accessor :stdout
      attr_accessor :stderr
      attr_accessor :exit_code
      attr_accessor :exit_signal

      def initialize(host, options = {})
        @host        = host
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
