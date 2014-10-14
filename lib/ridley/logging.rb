require 'logger'

module Ridley
  module Logging
    class << self
      # @return [Logger]
      def logger
        @logger ||= begin
          Ridley::Logging::Logger.new
        end
      end

      # @param [Logger, nil] obj
      #
      # @return [Logger]
      def set_logger(obj)
        @logger = (obj.nil? ? Logger.new('/dev/null') : obj)
      end
      alias_method :logger=, :set_logger
    end

    # @return [Logger]
    def logger
      Ridley::Logging.logger
    end
    alias_method :log, :logger
  end
end
