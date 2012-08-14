module Ridley
  module Resource
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods
    include ActiveModel::Validations
    include ActiveModel::Serializers::JSON

    included do
      attribute_method_suffix('=')
    end

    module ClassMethods
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

      # @return [Set]
      def attributes
        @attributes ||= Set.new
      end

      # @return [Hash]
      def attribute_defaults
        @attribute_defaults ||= Hash.new
      end

      # @param [String, Symbol] name
      # @option options [Object] :default
      #   defines the default value for the attribute
      #
      # @return [Set]
      def attribute(name, options = {})
        if options.has_key?(:default)
          default_for_attribute(name, options[:default])
        end
        define_attribute_method(name)
        attributes << name.to_sym
      end

      # @return [Array<Object>]
      def all
        Connection.active.get(self.resource_path).body.collect do |identity, location|
          new(self.chef_id => identity)
        end
      end
      
      # @param [String, #chef_id] object
      #
      # @return [nil, Object]
      def find(object)
        find!(object)
      rescue Errors::HTTPNotFound
        nil
      end

      # @param [String, #chef_id] object
      #
      # @raise [Errors::HTTPNotFound]
      #   if a resource with the given chef_id is not found
      #
      # @return [Object]
      def find!(object)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        new(Connection.active.get("#{self.resource_path}/#{chef_id}").body)
      end

      # @param [#to_hash] object
      #
      # @return [Object]
      def create(object)
        resource = new(object.to_hash)
        new_attributes = Connection.active.post(self.resource_path, resource.to_json).body
        resource.attributes = resource.attributes.merge(new_attributes)
        resource
      end

      # @param [String, #chef_id] object
      #
      # @return [Object]
      def delete(object)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        new(Connection.active.delete("#{self.resource_path}/#{chef_id}").body)
      end

      # @return [Array<Object>]
      def delete_all
        mutex = Mutex.new
        deleted = []
        resources = self.all

        Connection.thread_count.times.collect do
          Thread.new(resources, deleted) do |resources, deleted|
            while resource = mutex.synchronize { resources.pop }
              result = delete(resource)
              mutex.synchronize { deleted << result }
            end
          end
        end.each(&:join)

        deleted
      end

      # @param [#to_hash] object
      #
      # @return [Object]
      def update(object)
        resource = new(object.to_hash)
        new(Connection.active.put("#{self.resource_path}/#{resource.chef_id}", resource.to_json).body)
      end

      private

        def default_for_attribute(name, value)
          attribute_defaults[name.to_sym] = value
        end
    end

    # @param [Hash] attributes
    def initialize(attributes = {})
      self.attributes = self.class.attribute_defaults.merge(attributes)
    end

    # @param [String, Symbol] key
    #
    # @return [Object]
    def attribute(key)
      if instance_variable_defined?("@#{key}")
        instance_variable_get("@#{key}")
      else
        self.class.attribute_defaults[key]
      end
    end
    alias_method :[], :attribute

    # @param [String, Symbol] key
    # @param [Object] value
    #
    # @return [Object]
    def attribute=(key, value)
      instance_variable_set("@#{key}", value)
    end
    alias_method :[]=, :attribute=

    # @param [String, Symbol] key
    #
    # @return [Boolean]
    def attribute?(key)
      attribute(key).present?
    end

    # @return [Hash]
    def attributes
      {}.tap do |attrs|
        self.class.attributes.each do |attr|
          attrs[attr] = attribute(attr)
        end
      end
    end

    # @param [#to_hash] new_attributes
    #
    # @return [Hash]
    def attributes=(new_attributes)
      new_attributes.to_hash.symbolize_keys!

      self.class.attributes.each do |attr_name|
        send(:attribute=, attr_name, new_attributes[attr_name.to_sym])
      end
    end

    # Creates a resource on the target remote or updates one if the resource
    # already exists.
    #
    # @raise [Errors::InvalidResource]
    #   if the resource does not pass validations
    #
    # @return [Object]
    #   the created or updated object
    def save
      raise Errors::InvalidResource.new(self.errors) unless valid?

      self.class.create(self)
    rescue Errors::HTTPConflict
      self.class.update(self)
    end

    # @return [String]
    def chef_id
      attribute(self.class.chef_id)
    end

    # @param [String] json
    # @option options [Boolean] :symbolize_keys
    # @option options [Class, Symbol, String] :adapter
    #
    # @return [Object]
    def from_json(json, options = {})
      self.attributes = MultiJson.load(json, options)
      self
    end

    # @param [#to_hash] hash
    #
    # @return [Object]
    def from_hash(hash)
      self.attributes = hash.to_hash
      self
    end

    # @option options [Boolean] :symbolize_keys
    # @option options [Class, Symbol, String] :adapter
    #
    # @return [String]
    def to_json(options = {})
      MultiJson.dump(self.attributes, options)
    end
    alias_method :as_json, :to_json

    def to_hash
      self.attributes
    end

    def to_s
      self.attributes
    end

    # @param [Object] other
    #
    # @return [Boolean]
    def ==(other)
      self.attributes == other.attributes
    end

    # @param [Object] other
    #
    # @return [Boolean]
    def eql?(other)
      other.is_a?(self.class) && send(:==, other)
    end
  end
end
