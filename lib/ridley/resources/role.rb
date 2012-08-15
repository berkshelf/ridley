module Ridley
  class Role
    module DSL
      def role
        Ridley::Role
      end
    end

    include Ridley::Resource

    set_chef_id "name"
    set_chef_type "role"
    set_chef_json_class "Chef::Role"
    set_resource_path "roles"

    attribute :name
    validates_presence_of :name

    attribute :description, default: String.new
    attribute :default_attributes, default: Hash.new
    attribute :override_attributes, default: Hash.new
    attribute :run_list, default: Array.new
    attribute :env_run_lists, default: Hash.new
  end
end
