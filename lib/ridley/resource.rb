module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class Resource
    class << self
      # @return [String]
      def resource_path
        @resource_path ||= representation.chef_type.pluralize
      end

      # @param [String] path
      #
      # @return [String]
      def set_resource_path(path)
        @resource_path = path
      end

      def representation
        return @representation if @representation
        raise RuntimeError.new("no representation set")
      end

      def represented_by(klass)
        @representation = klass
      end
    end

    include Celluloid
    include Chozo::VariaModel
    include Comparable

    task_class TaskThread

    # @param [Celluloid::Registry] connection_registry
    def initialize(connection_registry)
      @connection_registry = connection_registry
    end

    def new(*args)
      self.class.representation.new(Actor.current, *args)
    end

    def connection
      @connection_registry[:connection_pool]
    end

    # @param [Ridley::Client] client
    #
    # @return [Array<Object>]
    def all
      connection.get(self.class.resource_path).body.collect do |identity, location|
        new(self.class.representation.chef_id => identity)
      end
    end

    # @param [String, #chef_id] object
    #
    # @return [nil, Object]
    def find(object)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      new(connection.get("#{self.class.resource_path}/#{chef_id}").body)
    rescue Errors::HTTPNotFound => ex
      nil
    end

    # @param [#to_hash] object
    #
    # @return [Object]
    def create(object)
      resource = new(object.to_hash)
      new_attributes = connection.post(self.class.resource_path, resource.to_json).body
      resource.mass_assign(resource._attributes_.deep_merge(new_attributes))
      resource
    end

    # @param [String, #chef_id] object
    #
    # @return [Object]
    def delete(object)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      new(connection.delete("#{self.class.resource_path}/#{chef_id}").body)
    end

    # @return [Array<Object>]
    def delete_all
      all.collect do |resource|
        future(:delete, resource)
      end.map(&:value)
    end

    # @param [#to_hash] object
    #
    # @return [Object]
    def update(object)
      resource = new(object.to_hash)
      new(connection.put("#{self.class.resource_path}/#{resource.chef_id}", resource.to_json).body)
    end
  end
end
