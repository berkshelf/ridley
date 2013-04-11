module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class RoleResource < Ridley::Resource
    set_chef_id "name"
    set_chef_type "role"
    set_chef_json_class "Chef::Role"
    set_resource_path "roles"
    represented_by Ridley::RoleObject
  end
end
