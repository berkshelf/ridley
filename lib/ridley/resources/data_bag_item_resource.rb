module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class DataBagItemResource < Ridley::Resource
    represented_by Ridley::DataBagItemObject

    attr_reader :encrypted_data_bag_secret

    # @param [Celluloid::Registry] connection_registry
    # @param [String] encrypted_data_bag_secret
    def initialize(connection_registry, encrypted_data_bag_secret)
      super(connection_registry)
      @encrypted_data_bag_secret = encrypted_data_bag_secret
    end

    # @param [Ridley::DataBagObject] data_bag
    #
    # @return [Array<Object>]
    def all(data_bag)
      connection.get("#{DataBagResource.resource_path}/#{data_bag.name}").body.collect do |id, location|
        new(data_bag, id: id)
      end
    end

    # @param [Ridley::DataBagObject] data_bag
    # @param [String, #chef_id] object
    #
    # @return [Ridley::DataBagItemObject]
    def find(data_bag, object)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      new(data_bag).from_hash(connection.get("#{DataBagResource.resource_path}/#{data_bag.name}/#{chef_id}").body)
    rescue Errors::HTTPNotFound
      nil
    end

    # @param [Ridley::DataBagObject] data_bag
    # @param [#to_hash] object
    #
    # @return [Ridley::DataBagItemObject]
    def create(data_bag, object)
      resource = new(data_bag, object.to_hash)
      unless resource.valid?
        abort Errors::InvalidResource.new(resource.errors)
      end

      new_attributes = connection.post("#{DataBagResource.resource_path}/#{data_bag.name}", resource.to_json).body
      resource.mass_assign(new_attributes)
      resource
    rescue Errors::HTTPConflict => ex
      abort(ex)
    end

    # @param [Ridley::DataBagObject] data_bag
    # @param [String, #chef_id] object
    #
    # @return [Ridley::DataBagItemObject]
    def delete(data_bag, object)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      new(data_bag).from_hash(connection.delete("#{DataBagResource.resource_path}/#{data_bag.name}/#{chef_id}").body)
    end

    # @param [Ridley::DataBagObject] data_bag
    #
    # @return [Array<Ridley::DataBagItemObject>]
    def delete_all(data_bag)
      all(data_bag).collect { |resource| future(:delete, data_bag, resource) }.map(&:value)
    end

    # @param [Ridley::DataBagObject] data_bag
    # @param [#to_hash] object
    #
    # @return [Ridley::DataBagItemObject]
    def update(data_bag, object)
      resource = new(data_bag, object.to_hash)
      new(data_bag).from_hash(
        connection.put("#{DataBagResource.resource_path}/#{data_bag.name}/#{resource.chef_id}", resource.to_json).body
      )
    rescue Errors::HTTPConflict => ex
      abort(ex)
    end
  end
end
