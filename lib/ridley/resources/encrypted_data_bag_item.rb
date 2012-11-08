module Ridley
  class EncryptedDataBagItem
    class << self
      # Finds a data bag item and decrypts it.
      #
      # @param [Ridley::Connection] connection
      # @param [Ridley::DataBag] data_bag
      # @param [String, #chef_id] object
      #
      # @return [nil, Ridley::DataBagItem]
      def find(connection, data_bag, object)
        find!(connection, data_bag, object)
      rescue Errors::HTTPNotFound
        nil
      end

      # Finds a data bag item and decrypts it. Throws an exception if the item doesn't exist.
      #
      # @param [Ridley::Connection] connection
      # @param [Ridley::DataBag] data_bag
      # @param [String, #chef_id] object
      #
      # @raise [Errors::HTTPNotFound]
      #   if a resource with the given chef_id is not found
      #
      # @return [nil, Ridley::DataBagItem]
      def find!(connection, data_bag, object)
        data_bag_item = DataBagItem.find!(connection, data_bag, object)
        data_bag_item.decrypt
        new(connection, data_bag, data_bag_item.attributes)
      end
    end

    attr_reader :data_bag
    attr_reader :attributes

    # @param [Ridley::Connection] connection
    # @param [Ridley::DataBag] data_bag
    # @param [#to_hash] attributes
    def initialize(connection, data_bag, attributes = {})
      @connection = connection
      @data_bag = data_bag
      @attributes = attributes
    end

    def to_s
      self.attributes
    end

    private

      attr_reader :connection
  end
end
