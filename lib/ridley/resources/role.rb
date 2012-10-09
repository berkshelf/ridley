module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Role
    include Ridley::Resource

    set_chef_id "name"
    set_chef_type "role"
    set_chef_json_class "Chef::Role"
    set_resource_path "roles"

    attribute :name
    validates_presence_of :name

    attribute :description, default: String.new
    attribute :default_attributes, default: HashWithIndifferentAccess.new
    attribute :override_attributes, default: HashWithIndifferentAccess.new
    attribute :run_list, default: Array.new
    attribute :env_run_lists, default: Hash.new

    # @param [Hash] hash
    def default_attributes=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end

    # @param [Hash] hash
    def override_attributes=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end

    # Set a role level override attribute given the dotted path representation of the Chef
    # attribute and value
    # 
    # @example setting and saving a node level override attribute
    #
    #   obj = node.role("why_god_why")
    #   obj.set_override_attribute("my_app.billing.enabled", false)
    #   obj.save
    #
    # @param [String] key
    # @param [Object] value
    #
    # @return [HashWithIndifferentAccess]
    def set_override_attribute(key, value)
      attr_hash = HashWithIndifferentAccess.from_dotted_path(key, value)
      self.override_attributes = self.override_attributes.merge(attr_hash)
    end

    # Set a role level default attribute given the dotted path representation of the Chef
    # attribute and value
    # 
    # @example setting and saving a node level default attribute
    #
    #   obj = node.role("why_god_why")
    #   obj.set_default_attribute("my_app.billing.enabled", false)
    #   obj.save
    #
    # @param [String] key
    # @param [Object] value
    #
    # @return [HashWithIndifferentAccess]
    def set_default_attribute(key, value)
      attr_hash = HashWithIndifferentAccess.from_dotted_path(key, value)
      self.default_attributes = self.default_attributes.merge(attr_hash)
    end
  end

  module DSL
    # Coerces instance functions into class functions on Ridley::Role. This coercion
    # sends an instance of the including class along to the class function.
    #
    # @see Ridley::Context
    #
    # @return [Ridley::Context]
    #   a context object to delegate instance functions to class functions on Ridley::Role
    def role
      Context.new(Ridley::Role, self)
    end
  end
end
