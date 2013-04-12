module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  # @api private
  class DBIChainLink
    attr_reader :data_bag
    attr_reader :item_resource

    # @param [Ridley::DataBagObject] data_bag
    #
    # @option options [Boolean] :encrypted (false)
    def initialize(data_bag, item_resource, options = {})
      options[:encrypted] ||= false

      @data_bag      = data_bag
      @item_resource = item_resource
    end

    def method_missing(fun, *args, &block)
      @item_resource.send(fun, data_bag, *args, &block)
    end
  end

  # @author Jamie Winsor <reset@riotgames.com>
  class DataBagObject < ChefObject
    set_chef_id "name"

    attribute :name,
      required: true

    def item
      DBIChainLink.new(self, resource.send(:dbi_resource))
    end

    def encrypted_item
      DBIChainLink.new(self, resource.send(:dbi_resource), encrypted: true)
    end
  end
end
