module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
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

      # @param [Ridley::Connection] connection
      #
      # @return [Array<Object>]
      def all(connection)
        connection.get(self.resource_path).body.collect do |identity, location|
          new(connection, self.chef_id => identity)
        end
      end
      
      # @param [Ridley::Connection] connection
      # @param [String, #chef_id] object
      #
      # @return [nil, Object]
      def find(connection, object)
        find!(connection, object)
      rescue Errors::HTTPNotFound
        nil
      end

      # @param [Ridley::Connection] connection
      # @param [String, #chef_id] object
      #
      # @raise [Errors::HTTPNotFound]
      #   if a resource with the given chef_id is not found
      #
      # @return [Object]
      def find!(connection, object)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        new(connection, connection.get("#{self.resource_path}/#{chef_id}").body)
      end

      # @param [Ridley::Connection] connection
      # @param [#to_hash] object
      #
      # @return [Object]
      def create(connection, object)
        resource = new(connection, object.to_hash)
        new_attributes = connection.post(self.resource_path, resource.to_json).body
        resource.attributes = resource.attributes.deep_merge(new_attributes)
        resource
      end

      # @param [Ridley::Connection] connection
      # @param [String, #chef_id] object
      #
      # @return [Object]
      def delete(connection, object)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        new(connection, connection.delete("#{self.resource_path}/#{chef_id}").body)
      end

      # @param [Ridley::Connection] connection
      #
      # @return [Array<Object>]
      def delete_all(connection)
        mutex = Mutex.new
        deleted = []
        resources = all(connection)

        resources.collect do |resource|
          Celluloid::Future.new {
            delete(connection, resource)
          }
        end.map(&:value)
      end

      # @param [Ridley::Connection] connection
      # @param [#to_hash] object
      #
      # @return [Object]
      def update(connection, object)
        resource = new(connection, object.to_hash)
        new(connection, connection.put("#{self.resource_path}/#{resource.chef_id}", resource.to_json).body)
      end
    end

    include Chozo::VariaModel
    include Comparable

    # @param [Ridley::Connection] connection
    # @param [Hash] new_attrs
    def initialize(connection, new_attrs = {})
      @connection = connection
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

      mass_assign(self.class.create(connection, self).attributes)
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

      mass_assign(self.class.update(connection, self).attributes)
      true
    end

    # Reload the attributes of the instantiated resource
    #
    # @return [Object]
    def reload
      mass_assign(self.class.find(connection, self).attributes)
      self
    end

    # @return [String]
    def chef_id
      get_attribute(self.class.chef_id)
    end

    def to_s
      self.attributes
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

      attr_reader :connection
  end
end
