require 'ridley/resources/data_bag_item_resource'

module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class DataBagResource < Ridley::Resource
    set_resource_path "data"
    represented_by Ridley::DataBagObject

    finalizer do
      dbi_resource.terminate if dbi_resource && dbi_resource.alive?
    end

    def initialize(connection_registry)
      super
      @dbi_resource = DataBagItemResource.new_link(connection_registry)
    end

    # @param [String, #chef_id] object
    #
    # @return [nil, Ridley::DataBagResource]
    def find(object)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      connection.get("#{self.resource_path}/#{chef_id}")
      new(name: chef_id)
    rescue Errors::HTTPNotFound
      nil
    end

    private

      attr_reader :dbi_resource
  end
end
