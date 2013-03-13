module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class EncryptedDataBagItemResource
    class << self
      # Finds a data bag item and decrypts it.
      #
      # @param [Ridley::Client] client
      # @param [Ridley::DataBagResource] data_bag
      # @param [String, #chef_id] object
      #
      # @return [nil, Ridley::DataBagItemResource]
      def find(client, data_bag, object)
        find!(client, data_bag, object)
      rescue Errors::HTTPNotFound
        nil
      end

      # Finds a data bag item and decrypts it. Throws an exception if the item doesn't exist.
      #
      # @param [Ridley::Client] client
      # @param [Ridley::DataBagResource] data_bag
      # @param [String, #chef_id] object
      #
      # @raise [Errors::HTTPNotFound]
      #   if a resource with the given chef_id is not found
      #
      # @return [nil, Ridley::DataBagItemResource]
      def find!(client, data_bag, object)
        data_bag_item = DataBagItemResource.find!(client, data_bag, object)
        data_bag_item.decrypt
        new(client, data_bag, data_bag_item.attributes)
      end
    end

    attr_reader :data_bag
    attr_reader :attributes

    # @param [Ridley::Client] client
    # @param [Ridley::DataBagResource] data_bag
    # @param [#to_hash] attributes
    def initialize(client, data_bag, attributes = {})
      @client     = client
      @data_bag   = data_bag
      @attributes = attributes
    end

    def to_s
      self.attributes
    end

    private

      attr_reader :client
  end
end
