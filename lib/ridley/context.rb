module Ridley
  class Context
    attr_reader :resource
    attr_reader :connection

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
