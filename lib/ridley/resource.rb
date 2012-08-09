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

      # @param [String, Symbol]
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
        if options[:default]
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
      
      # @return [Object]
      def find(oid)
        attrs = Connection.active.get("#{self.resource_path}/#{oid}").body
        new(attrs)
      end

      # @return [Object]
      def create(attributes)
        attrs = Connection.active.post(self.resource_path, attributes.to_json).body
        new(attrs)
      end

      # @return [Object]
      def delete(oid)
        attrs = Connection.active.delete("#{self.resource_path}/#{oid}").body
        new(attrs)
      end

      # @return [Object]
      def update(object)
        attrs = Connection.active.put("#{self.resource_path}/#{object[self.chef_id]}", object.to_json).body
        new(attrs)
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
      instance_variable_get("@#{key}") || self.class.attribute_defaults[key]
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
      instance_variable_get("@#{key}").present?
    end

    # @return [Hash]
    def attributes
      {}.tap do |attrs|
        self.class.attributes.each do |attr|
          attrs[attr] = attribute(attr)
        end
      end
    end

    # @param [Hash] new_attributes
    #
    # @return [Hash]
    def attributes=(new_attributes)
      new_attributes.symbolize_keys!

      self.class.attributes.each do |attr_name|
        send(:attribute=, attr_name, new_attributes[attr_name.to_sym])
      end
    end

    # @return [Object]
    def save
      raise "implement me, Jamie"
    end

    def to_json
      MultiJson.dump(self.attributes)
    end

    def as_json(options = {})
      options.merge!(root: false)
      super(options)
    end

    def from_json(json, include_root = false)
      super(json, include_root)
    end

    def to_s
      self.attributes
    end
  end
end
