module Ridley
  # @api private
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Context
    attr_reader :resource
    attr_reader :connection

    # @param [Constant] resource
    #   the constant of the class to send class functions to
    # @param [Ridley::Connection] connection
    #   the connection to use when sending class functions to resources
    def initialize(resource, connection)
      @resource = resource
      @connection = connection
    end

    def new(*args)
      resource.send(:new, connection, *args)
    end

    def method_missing(fun, *args, &block)
      resource.send(fun, connection, *args, &block)
    end
  end
end
