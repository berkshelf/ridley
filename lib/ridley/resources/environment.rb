module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Environment
    include Ridley::Resource
    
    class << self
      # Delete all of the environments on the remote connection. The
      # '_default' environment will never be deleted.
      #
      # @param [Ridley::Connection] connection
      #
      # @return [Array<Ridley::Environment>]
      def delete_all(connection)
        envs = all(connection).reject { |env| env.name.to_s == '_default' }
        envs.collect { |obj| delete(connection, obj) }
      end
    end

    set_chef_id "name"
    set_chef_type "environment"
    set_chef_json_class "Chef::Environment"
    set_resource_path "environments"

    attribute :name
    validates_presence_of :name

    attribute :description, default: String.new
    attribute :default_attributes, default: HashWithIndifferentAccess.new
    attribute :override_attributes, default: HashWithIndifferentAccess.new
    attribute :cookbook_versions, default: HashWithIndifferentAccess.new

    # @param [Hash] hash
    def default_attributes=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end

    # @param [Hash] hash
    def override_attributes=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end

    def cookbook_versions=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end

    # Set an environment level default attribute given the dotted path representation of
    # the Chef attribute and value
    #
    # @example setting and saving an environment level default attribute
    #
    #   obj = environment.find("production")
    #   obj.set_defualt_attribute("my_app.billing.enabled", false)
    #   obj.save
    #
    # @param [String] key
    # @param [Object] value
    #
    # @return [HashWithIndifferentAccess]
    def set_default_attribute(key, value)
      attr_hash = HashWithIndifferentAccess.from_dotted_path(key, value)
      self.default_attributes = self.default_attributes.deep_merge(attr_hash)
    end

    # Set an environment level override attribute given the dotted path representation of
    # the Chef attribute and value
    # 
    # @example setting and saving an environment level override attribute
    #
    #   obj = environment.find("production")
    #   obj.set_override_attribute("my_app.billing.enabled", false)
    #   obj.save
    #
    # @param [String] key
    # @param [Object] value
    #
    # @return [HashWithIndifferentAccess]
    def set_override_attribute(key, value)
      attr_hash = HashWithIndifferentAccess.from_dotted_path(key, value)
      self.override_attributes = self.override_attributes.deep_merge(attr_hash)
    end
  end

  module DSL
    # Coerces instance functions into class functions on Ridley::Environment. This coercion
    # sends an instance of the including class along to the class function.
    #
    # @see Ridley::ChainLink
    #
    # @return [Ridley::ChainLink]
    #   a context object to delegate instance functions to class functions on Ridley::Environment
    def environment
      ChainLink.new(self, Ridley::Environment)
    end
  end
end
