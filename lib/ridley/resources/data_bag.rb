module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  # @api private
  class DBIChainLink
    attr_reader :data_bag
    attr_reader :connection
    attr_reader :klass

    # @param [Ridley::DataBag] data_bag
    def initialize(data_bag, connection, options = {})
      options[:encrypted] ||= false

      @data_bag = data_bag
      @connection = connection
      @klass = options[:encrypted] ? Ridley::EncryptedDataBagItem : Ridley::DataBagItem
    end

    def new(*args)
      klass.send(:new, connection, data_bag, *args)
    end

    def method_missing(fun, *args, &block)
      klass.send(fun, connection, data_bag, *args, &block)
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
        connection.get("#{self.resource_path}/#{chef_id}")
        new(connection, name: chef_id)
      end
    end

    set_chef_id "name"
    set_resource_path "data"

    attribute :name
    validates_presence_of :name

    def item
      DBIChainLink.new(self, connection)
    end

    def encrypted_item
      DBIChainLink.new(self, connection, encrypted: true)
    end
  end

  module DSL
    # Coerces instance functions into class functions on Ridley::DataBag. This coercion
    # sends an instance of the including class along to the class function.
    #
    # @see Ridley::ChainLink
    #
    # @return [Ridley::ChainLink]
    #   a context object to delegate instance functions to class functions on Ridley::DataBag
    def data_bag
      ChainLink.new(self, Ridley::DataBag)
    end
  end
end
