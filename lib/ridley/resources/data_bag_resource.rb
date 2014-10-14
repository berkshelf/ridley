module Ridley
  class DataBagResource < Ridley::Resource
    require_relative 'data_bag_item_resource'

    set_resource_path "data"
    represented_by Ridley::DataBagObject

    attr_reader :item_resource

    finalizer :finalize_callback

    # @param [Celluloid::Registry] connection_registry
    # @param [String] data_bag_secret
    def initialize(connection_registry, data_bag_secret)
      super(connection_registry)
      @item_resource = DataBagItemResource.new_link(connection_registry, data_bag_secret)
    end

    # @param [String, #chef_id] object
    #
    # @return [nil, Ridley::DataBagResource]
    def find(object)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      request(:get, "#{self.class.resource_path}/#{chef_id}")
      new(name: chef_id)
    rescue AbortError => ex
      return nil if ex.cause.is_a?(Errors::HTTPNotFound)
      abort(ex.cause)
    end

    private

      def finalize_callback
        item_resource.async.terminate if item_resource
      end
  end
end
