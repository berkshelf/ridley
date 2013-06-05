module Ridley
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
      request(:get, "#{DataBagResource.resource_path}/#{data_bag.name}").collect do |id, location|
        new(data_bag, id: id)
      end
    end

    # @param [Ridley::DataBagObject] data_bag
    # @param [String, #chef_id] object
    #
    # @return [Ridley::DataBagItemObject, nil]
    def find(data_bag, object)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      new(data_bag).from_hash(request(:get, "#{DataBagResource.resource_path}/#{data_bag.name}/#{chef_id}"))
    rescue AbortError => ex
      return nil if ex.cause.is_a?(Errors::HTTPNotFound)
      abort(ex.cause)
    end

    # @param [Ridley::DataBagObject] data_bag
    # @param [#to_hash] object
    #
    # @return [Ridley::DataBagItemObject, nil]
    def create(data_bag, object)
      resource = new(data_bag, object.to_hash)
      unless resource.valid?
        abort Errors::InvalidResource.new(resource.errors)
      end

      new_attributes = request(:post, "#{DataBagResource.resource_path}/#{data_bag.name}", resource.to_json)
      resource.mass_assign(new_attributes)
      resource
    end

    # @param [Ridley::DataBagObject] data_bag
    # @param [String, #chef_id] object
    #
    # @return [Ridley::DataBagItemObject, nil]
    def delete(data_bag, object)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      new(data_bag).from_hash(request(:delete, "#{DataBagResource.resource_path}/#{data_bag.name}/#{chef_id}"))
    rescue AbortError => ex
      return nil if ex.cause.is_a?(Errors::HTTPNotFound)
      abort(ex.cause)
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
    # @return [Ridley::DataBagItemObject, nil]
    def update(data_bag, object)
      resource = new(data_bag, object.to_hash)
      new(data_bag).from_hash(
        request(:put, "#{DataBagResource.resource_path}/#{data_bag.name}/#{resource.chef_id}", resource.to_json)
      )
    rescue AbortError => ex
      return nil if ex.cause.is_a?(Errors::HTTPConflict)
      abort(ex.cause)
    end
  end
end
