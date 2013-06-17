module Ridley
  class RoleObject < Ridley::ChefObject
    set_chef_id "name"
    set_chef_type "role"
    set_chef_json_class "Chef::Role"

    attribute :name,
      required: true

    attribute :description,
      default: String.new

    attribute :default_attributes,
      default: Hashie::Mash.new

    attribute :override_attributes,
      default: Hashie::Mash.new

    attribute :run_list,
      default: Array.new

    attribute :env_run_lists,
      default: Hash.new

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
    # @return [Hashie::Mash]
    def set_override_attribute(key, value)
      attr_hash = Hashie::Mash.from_dotted_path(key, value)
      self.override_attributes = self.override_attributes.deep_merge(attr_hash)
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
    # @return [Hashie::Mash]
    def set_default_attribute(key, value)
      attr_hash = Hashie::Mash.from_dotted_path(key, value)
      self.default_attributes = self.default_attributes.deep_merge(attr_hash)
    end
  end
end
