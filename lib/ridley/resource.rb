module Ridley
  class Resource
    class << self
      # @return [String]
      def resource_path
        @resource_path ||= representation.chef_type
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

    # @param [Celluloid::Registry] connection_registry
    def initialize(connection_registry)
      @connection_registry = connection_registry
    end

    def new(*args)
      self.class.representation.new(Actor.current, *args)
    end

    # Used to build a representation from a file with the current Actor's resource
    #
    # @param [String] filename
    #   a full filename from which to build this representation (currently only supports .json files)
    #
    # @return [representation.class]
    def from_file(filename)
      from_json(File.read(filename))
    end

    # Used to build a representation from a serialized json string with the current Actor's resource
    #
    # @param [String] json
    #   a representation serialized into json
    #
    # @return [representation.class]
    def from_json(json)
      new(JSON.parse(json))
    end

    # @return [Ridley::Connection]
    def connection
      @connection_registry[:connection_pool]
    end

    # @param [Ridley::Client] client
    #
    # @return [Array<Object>]
    def all
      request(:get, self.class.resource_path).collect do |identity, location|
        new(self.class.representation.chef_id => identity)
      end
    end

    # @param [String, #chef_id] object
    #
    # @return [Object, nil]
    def find(object)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      new(request(:get, "#{self.class.resource_path}/#{chef_id}"))
    rescue AbortError => ex
      return nil if ex.cause.is_a?(Errors::HTTPNotFound)
      abort(ex.cause)
    end

    # @param [#to_hash] object
    #
    # @return [Object]
    def create(object)
      resource = new(object.to_hash)
      new_attributes = request(:post, self.class.resource_path, resource.to_json)
      resource.mass_assign(resource._attributes_.deep_merge(new_attributes))
      resource
    end

    # @param [String, #chef_id] object
    #
    # @return [Object, nil]
    def delete(object)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      new(request(:delete, "#{self.class.resource_path}/#{chef_id}"))
    rescue AbortError => ex
      return nil if ex.cause.is_a?(Errors::HTTPNotFound)
      abort(ex.cause)
    end

    # @return [Array<Object>]
    def delete_all
      all.collect { |resource| future(:delete, resource) }.map(&:value)
    end

    # @param [#to_hash] object
    #
    # @return [Object, nil]
    def update(object)
      resource = new(object.to_hash)
      new(request(:put, "#{self.class.resource_path}/#{resource.chef_id}", resource.to_json))
    rescue AbortError => ex
      return nil if ex.cause.is_a?(Errors::HTTPConflict)
      abort(ex.cause)
    end

    private

      # @param [Symbol] method
      def request(method, *args)
        raw_request(method, *args).body
      end

      # @param [Symbol] method
      def raw_request(method, *args)
        unless Connection::METHODS.include?(method)
          raise Errors::HTTPUnknownMethod, "unknown http method: #{method}"
        end

        connection.send(method, *args)
      rescue Errors::HTTPError, Errors::ClientError => ex
        abort(ex)
      end
  end
end
