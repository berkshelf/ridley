require 'ridley/resources/data_bag_item_resource'
require 'ridley/resources/encrypted_data_bag_item_resource'

module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  # @api private
  class DBIChainLink
    attr_reader :data_bag
    attr_reader :client
    attr_reader :klass

    # @param [Ridley::DataBagResource] data_bag
    # @param [Ridley::Client] client
    #
    # @option options [Boolean] :encrypted (false)
    def initialize(data_bag, client, options = {})
      options[:encrypted] ||= false

      @data_bag = data_bag
      @client = client
      @klass = options[:encrypted] ? Ridley::EncryptedDataBagItemResource : Ridley::DataBagItemResource
    end

    def new(*args)
      klass.send(:new, client, data_bag, *args)
    end

    def method_missing(fun, *args, &block)
      klass.send(fun, client, data_bag, *args, &block)
    end
  end

  # @author Jamie Winsor <reset@riotgames.com>
  class DataBagResource < Ridley::Resource
    class << self
      # @param [Ridley::Client] client
      # @param [String, #chef_id] object
      #
      # @return [nil, Ridley::DataBagResource]
      def find(client, object)
        find!(client, object)
      rescue Errors::HTTPNotFound
        nil
      end

      # @param [Ridley::Client] client
      # @param [String, #chef_id] object
      #
      # @raise [Errors::HTTPNotFound]
      #   if a resource with the given chef_id is not found
      #
      # @return [Ridley::DataBagResource]
      def find!(client, object)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        client.connection.get("#{self.resource_path}/#{chef_id}")
        new(client, name: chef_id)
      end
    end

    set_chef_id "name"
    set_resource_path "data"

    attribute :name,
      required: true

    def item
      DBIChainLink.new(self, client)
    end

    def encrypted_item
      DBIChainLink.new(self, client, encrypted: true)
    end
  end
end
