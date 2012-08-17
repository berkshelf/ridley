module Ridley 
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Node
    include Ridley::Resource

    set_chef_id "name"
    set_chef_type "node"
    set_chef_json_class "Chef::Node"
    set_resource_path "nodes"

    attribute :name
    validates_presence_of :name

    attribute :chef_environment, default: "_default"
    attribute :automatic, default: Hash.new
    attribute :normal, default: Hash.new
    attribute :default, default: Hash.new
    attribute :override, default: Hash.new
    attribute :run_list, default: Array.new
  end
  
  module DSL
    # Coerces instance functions into class functions on Ridley::Node. This coercion
    # sends an instance of the including class along to the class function.
    #
    # @see Ridley::Context
    #
    # @return [Ridley::Context]
    #   a context object to delegate instance functions to class functions on Ridley::Node
    def node
      Context.new(Ridley::Node, self)
    end
  end
end
