module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class EnvironmentResource < Ridley::Resource
    set_chef_type "environment"
    set_chef_json_class "Chef::Environment"
    set_resource_path "environments"
    represented_by Ridley::EnvironmentObject

    # Delete all of the environments on the client. The '_default' environment
    # will never be deleted.
    #
    # @return [Array<Ridley::EnvironmentObject>]
    def delete_all
      envs = all.reject { |env| env.name.to_s == '_default' }
      envs.collect do |resource|
        future(:delete, resource)
      end.map(&:value)
    end
  end
end
