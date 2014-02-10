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
    def unset_default_attribute(key)
      unset_attribute(key, :default)
    end
    alias :delete_default_attribute :unset_default_attribute

    # Removes a environment override attribute given its dotted path
    # representation. Returns the override attributes of the environment.
    # 
    # @param [String] key
    #   the dotted path to an attribute
    # 
    # @return [Hashie::Mash]
    def unset_override_attribute(key)
      unset_attribute(key, :override)
    end
    alias :delete_override_attribute :unset_override_attribute

    private

      # Deletes an attribute at the given precedence using its dotted-path key.
      # 
      # @param [String] key
      #   the dotted path to an attribute
      # @param [Symbol] precedence
      #   the precedence level to delete the attribute from
      # 
      # @return [Hashie::Mash]
      def unset_attribute(key, precedence)
        keys = key.split(".")
        leaf_key = keys.pop
  
        attributes_to_change = case precedence
                               when :default
                                 self.default_attributes  
                               when :override
                                 self.override_attributes
                               end
  
        leaf_attributes = keys.inject(attributes_to_change) do |attributes, key|
          if attributes[key] && attributes[key].kind_of?(Hashie::Mash)
            attributes = attributes[key]
          else 
            return attributes_to_change
          end
        end
        leaf_attributes.delete(leaf_key)
        return attributes_to_change
      end
  end
end
