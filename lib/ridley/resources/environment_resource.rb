module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class EnvironmentResource < Ridley::Resource
    class << self
      # Delete all of the environments on the client. The '_default' environment
      # will never be deleted.
      #
      # @param [Ridley::Client] client
      #
      # @return [Array<Ridley::EnvironmentResource>]
      def delete_all(client)
        envs = all(client).reject { |env| env.name.to_s == '_default' }
        envs.collect { |obj| delete(client, obj) }
      end
    end

    set_chef_id "name"
    set_chef_type "environment"
    set_chef_json_class "Chef::Environment"
    set_resource_path "environments"

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
end
