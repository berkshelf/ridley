module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class DataBagItemResource < Ridley::Resource
    represented_by Ridley::DataBagItemObject

    # @param [Ridley::DataBagObject] data_bag
    #
    # @return [Array<Object>]
    def all(data_bag)
      connection.get("#{data_bag.class.resource_path}/#{data_bag.name}").body.collect do |id, location|
        new(data_bag, id: id)
      end
    end

    # @param [Ridley::DataBagObject] data_bag
    # @param [String, #chef_id] object
    #
    # @return [nil, Ridley::DataBagItemResource]
    def find(data_bag, object)
      find!(data_bag, object)
    rescue Errors::HTTPNotFound
      nil
    end

    # @param [Ridley::DataBagObject] data_bag
    # @param [String, #chef_id] object
    #
    # @raise [Errors::HTTPNotFound]
    #   if a resource with the given chef_id is not found
    #
    # @return [Ridley::DataBagItemResource]
    def find!(data_bag, object)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      new(data_bag).from_hash(connection.get("#{data_bag.class.resource_path}/#{data_bag.name}/#{chef_id}").body)
    end

    # @param [Ridley::DataBagObject] data_bag
    # @param [#to_hash] object
    #
    # @return [Ridley::DataBagItemResource]
    def create(data_bag, object)
      resource = new(data_bag, object.to_hash)
      unless resource.valid?
        raise Errors::InvalidResource.new(resource.errors)
      end

      new_attributes = connection.post("#{data_bag.class.resource_path}/#{data_bag.name}", resource.to_json).body
      resource.mass_assign(new_attributes)
      resource
    end

    # @param [Ridley::DataBagObject] data_bag
    # @param [String, #chef_id] object
    #
    # @return [Ridley::DataBagItemResource]
    def delete(data_bag, object)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      new(data_bag).from_hash(connection.delete("#{data_bag.class.resource_path}/#{data_bag.name}/#{chef_id}").body)
    end

    # @param [Ridley::DataBagObject] data_bag
    #
    # @return [Array<Ridley::DataBagItemResource>]
    def delete_all(data_bag)
      mutex = Mutex.new
      deleted = []

      all(data_bag).collect do |resource|
        future(:delete, data_bag, resource)
      end.map(&:value)
    end

    # @param [Ridley::DataBagObject] data_bag
    # @param [#to_hash] object
    #
    # @return [Ridley::DataBagItemResource]
    def update(data_bag, object)
      resource = new(data_bag, object.to_hash)
      new(data_bag).from_hash(
        connection.put("#{data_bag.class.resource_path}/#{data_bag.name}/#{resource.chef_id}", resource.to_json).body
      )
    end
  end
end
