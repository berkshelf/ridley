module Ridley
  class EnvironmentObject < Ridley::ChefObject
    set_chef_id "name"
    set_chef_type "environment"
    set_chef_json_class "Chef::Environment"

    attribute :name,
      required: true

    attribute :description,
      default: String.new

    attribute :default_attributes,
      default: Hashie::Mash.new

    attribute :override_attributes,
      default: Hashie::Mash.new

    attribute :cookbook_versions,
      default: Hashie::Mash.new

    # Set an environment level default attribute given the dotted path representation of
    # the Chef attribute and value
    #
    # @example setting and saving an environment level default attribute
    #
    #   obj = environment.find("production")
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
    # @return [Hashie::Mash]
    def set_override_attribute(key, value)
      attr_hash = Hashie::Mash.from_dotted_path(key, value)
      self.override_attributes = self.override_attributes.deep_merge(attr_hash)
    end

    # Removes a environment default attribute given its dotted path
    # representation. Returns the default attributes of the environment.
    # 
    # @param [String] key
    #   the dotted path to an attribute
    # 
    # @return [Hashie::Mash]
    def delete_default_attribute(key)
      delete_attribute(key, :default)
    end

    # Removes a environment override attribute given its dotted path
    # representation. Returns the override attributes of the environment.
    # 
    # @param [String] key
    #   the dotted path to an attribute
    # 
    # @return [Hashie::Mash]
    def delete_override_attribute(key)
      delete_attribute(key, :override)
    end

    private

      # Deletes an attribute at the given precedence using its dotted-path key.
      # 
      # @param [String] key
      #   the dotted path to an attribute
      # @param [Symbol] precedence
      #   the precedence level to delete the attribute from
      # 
      # @return [Hashie::Mash]
      def delete_attribute(key, precedence)
        dotted_path = key.split('.')
        leaf_key = dotted_path.pop
        case precedence
        when :default
          attributes_to_change = self.default_attributes  
        when :override
          attributes_to_change = self.override_attributes
        end
        leaf_hash = dotted_path.inject(attributes_to_change) { |hash, element| hash[element] }
        leaf_hash.delete(leaf_key) unless leaf_hash.nil?
        attributes_to_change
      end
  end
end
