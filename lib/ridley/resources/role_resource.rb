module Ridley
  class RoleResource < Ridley::Resource
    set_resource_path "roles"
    represented_by Ridley::RoleObject
  end
end
