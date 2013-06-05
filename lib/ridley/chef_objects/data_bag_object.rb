module Ridley
  class DataBagObject < ChefObject
    set_chef_id "name"

    attribute :name,
      required: true

    def item
      DataBagItemProxy.new(self, resource.item_resource)
    end

    # @api private
    class DataBagItemProxy
      attr_reader :data_bag_object
      attr_reader :item_resource

      # @param [Ridley::DataBagObject] data_bag_object
      # @param [Ridley::DataBagItemResource] item_resource
      def initialize(data_bag_object, item_resource)
        @data_bag_object = data_bag_object
        @item_resource   = item_resource
      end

      def method_missing(fun, *args, &block)
        @item_resource.send(fun, data_bag_object, *args, &block)
      end
    end
  end
end
