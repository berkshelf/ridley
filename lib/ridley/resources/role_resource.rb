module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class RoleResource < Ridley::Resource
    set_resource_path "roles"
    represented_by Ridley::RoleObject
  end
end
