module Ridley
  # @api private
  # @author Jamie Winsor <jamie@vialstudios.com>
  class DBIContext
    attr_reader :data_bag
    attr_reader :connection

    # @param [Ridley::DataBag] data_bag
    def initialize(data_bag, connection)
      @data_bag = data_bag
      @connection = connection
    end

    def new(*args)
      Ridley::DataBagItem.send(:new, connection, data_bag, *args)
    end

    def method_missing(fun, *args, &block)
      Ridley::DataBagItem.send(fun, connection, data_bag, *args, &block)
    end
  end

  # @author Jamie Winsor <jamie@vialstudios.com>
  class DataBag
    include Ridley::Resource

    class << self
      # @param [Ridley::Connection] connection
      # @param [String, #chef_id] object
      #
      # @return [nil, Ridley::DataBag]
      def find(connection, object)
        find!(connection, object)
      rescue Errors::HTTPNotFound
        nil
      end

      # @param [Ridley::Connection] connection
      # @param [String, #chef_id] object
      #
      # @raise [Errors::HTTPNotFound]
      #   if a resource with the given chef_id is not found
      #
      # @return [Ridley::DataBag]
      def find!(connection, object)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        name, uri = connection.get("#{self.resource_path}/#{chef_id}").body.first
        new(connection, name: name)
      end
    end

    set_chef_id "name"
    set_resource_path "data"

    attribute :name
    validates_presence_of :name

    def item
      @dbi_context ||= DBIContext.new(self, connection)
    end
  end

  module DSL
    # Coerces instance functions into class functions on Ridley::DataBag. This coercion
    # sends an instance of the including class along to the class function.
    #
    # @see Ridley::Context
    #
    # @return [Ridley::Context]
    #   a context object to delegate instance functions to class functions on Ridley::DataBag
    def data_bag
      Context.new(Ridley::DataBag, self)
    end
  end
end
