module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class DataBagObject < ChefObject
    set_chef_id "name"

    attribute :name,
      required: true

    def item
      DBIChainLink.new(self, resource.item_resource)
    end

    # @author Jamie Winsor <reset@riotgames.com>
    # @api private
    class DBIChainLink
      attr_reader :data_bag
      attr_reader :item_resource

      # @param [Ridley::DataBagObject] data_bag
      # @param [Ridley::DataBagItemResource] item_resource
      def initialize(data_bag, item_resource)
        @data_bag      = data_bag
        @item_resource = item_resource
      end

      def method_missing(fun, *args, &block)
        @item_resource.send(fun, data_bag, *args, &block)
      end
    end
  end
end
