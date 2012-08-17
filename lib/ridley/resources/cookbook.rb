module Ridley
  class Cookbook    
    include Ridley::Resource

    set_chef_id "name"
    set_chef_type "cookbook"
    set_chef_json_class "Chef::Cookbook"
    set_resource_path "cookbooks"

    attribute :name
    validates_presence_of :name
  end

  module DSL
    def cookbook
      Context.new(Ridley::Cookbook, self)
    end
  end
end
