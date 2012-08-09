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
    validates_presence_of :description

    attribute :default_attributes, default: Hash.new
    validates_presence_of :default_attributes

    attribute :override_attributes, default: Hash.new
    validates_presence_of :override_attributes

    attribute :run_list, default: Array.new
    validates_presence_of :run_list    
  end
end
