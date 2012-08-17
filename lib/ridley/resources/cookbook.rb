module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
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
    # Coerces instance functions into class functions on Ridley::Cookbook. This coercion
    # sends an instance of the including class along to the class function.
    #
    # @see Ridley::Context
    #
    # @return [Ridley::Context]
    #   a context object to delegate instance functions to class functions on Ridley::Cookbook
    def cookbook
      Context.new(Ridley::Cookbook, self)
    end
  end
end
