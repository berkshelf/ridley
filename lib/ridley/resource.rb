module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class Resource
    class << self
      # @return [String, nil]
      def chef_id
        @chef_id
      end

      # @param [String, Symbol] identifier
      #
      # @return [String]
      def set_chef_id(identifier)
        @chef_id = identifier.to_sym
      end

      # @return [String]
      def resource_path
        @resource_path ||= self.chef_type.pluralize
      end

      # @param [String] path
      #
      # @return [String]
      def set_resource_path(path)
        @resource_path = path
      end

      # @return [String]
      def chef_type
        @chef_type ||= self.class.name.underscore
      end

      # @param [String, Symbol] type
      #
      # @return [String]
      def set_chef_type(type)
        @chef_type = type.to_s
        attribute(:chef_type, default: type)
      end

      # @return [String, nil]
      def chef_json_class
        @chef_json_class
      end

      # @param [String, Symbol] klass
      #
      # @return [String]
      def set_chef_json_class(klass)
        @chef_json_class = klass
        attribute(:json_class, default: klass)
      end

      # @param [Ridley::Client] client
      #
      # @return [Array<Object>]
      def all(client)
        client.connection.get(self.resource_path).body.collect do |identity, location|
          new(client, self.chef_id => identity)
        end
      end
      
      # @param [Ridley::Client] client
      # @param [String, #chef_id] object
      #
      # @return [nil, Object]
      def find(client, object)
        find!(client, object)
      rescue Errors::ResourceNotFound
        nil
      end

      # @param [Ridley::Client] client
      # @param [String, #chef_id] object
      #
      # @raise [Errors::HTTPNotFound]
      #   if a resource with the given chef_id is not found
      #
      # @return [Object]
      def find!(client, object)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        new(client, client.connection.get("#{self.resource_path}/#{chef_id}").body)
      rescue Errors::HTTPNotFound => ex
        raise Errors::ResourceNotFound, ex
      end

      # @param [Ridley::Client] client
      # @param [#to_hash] object
      #
      # @return [Object]
      def create(client, object)
        resource = new(client, object.to_hash)
        new_attributes = client.connection.post(self.resource_path, resource.to_json).body
        resource.mass_assign(resource._attributes_.deep_merge(new_attributes))
        resource
      end

      # @param [Ridley::Client] client
      # @param [String, #chef_id] object
      #
      # @return [Object]
      def delete(client, object)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        new(client, client.connection.delete("#{self.resource_path}/#{chef_id}").body)
      end

      # @param [Ridley::Client] client
      #
      # @return [Array<Object>]
      def delete_all(client)
        mutex = Mutex.new
        deleted = []

        all(client).collect do |resource|
          Celluloid::Future.new {
            delete(client, resource)
          }
        end.map(&:value)
      end

      # @param [Ridley::Client] client
      # @param [#to_hash] object
      #
      # @return [Object]
      def update(client, object)
        resource = new(client, object.to_hash)
        new(client, client.connection.put("#{self.resource_path}/#{resource.chef_id}", resource.to_json).body)
      end
    end

    include Chozo::VariaModel
    include Comparable

    # @param [Ridley::Client] client
    # @param [Hash] new_attrs
    def initialize(client, new_attrs = {})
      @client = client
      mass_assign(new_attrs)
    end

    # Creates a resource on the target remote or updates one if the resource
    # already exists.
    #
    # @raise [Errors::InvalidResource]
    #   if the resource does not pass validations
    #
    # @return [Boolean]
    def save
      raise Errors::InvalidResource.new(self.errors) unless valid?

      mass_assign(self.class.create(client, self)._attributes_)
      true
    rescue Errors::HTTPConflict
      self.update
      true
    end

    # Updates the instantiated resource on the target remote with any changes made
    # to self
    #
    # @raise [Errors::InvalidResource]
    #   if the resource does not pass validations
    #
    # @return [Boolean]
    def update
      raise Errors::InvalidResource.new(self.errors) unless valid?

      mass_assign(self.class.update(client, self)._attributes_)
      true
    end

    # Reload the attributes of the instantiated resource
    #
    # @return [Object]
    def reload
      mass_assign(self.class.find(client, self)._attributes_)
      self
    end

    # @return [String]
    def chef_id
      get_attribute(self.class.chef_id)
    end

    def to_s
      "#{self.chef_id}: #{self._attributes_}"
    end

    # @param [Object] other
    #
    # @return [Boolean]
    def <=>(other)
      self.chef_id <=> other.chef_id
    end

    def ==(other)
      self.chef_id == other.chef_id
    end

    # @param [Object] other
    #
    # @return [Boolean]
    def eql?(other)
      self.class == other.class && self == other
    end

    def hash
      self.chef_id.hash
    end

    private

      attr_reader :client
  end
end
