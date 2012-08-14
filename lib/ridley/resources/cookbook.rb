module Ridley
  class Cookbook
    module DSL
      def cookbook
        Ridley::Cookbook
      end
    end
    
    include Ridley::Resource

    set_chef_id "name"
    set_chef_type "cookbook"
    set_chef_json_class "Chef::Cookbook"
    set_resource_path "cookbooks"

    attribute :name
    validates_presence_of :name
  end
end
