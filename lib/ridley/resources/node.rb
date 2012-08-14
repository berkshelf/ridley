module Ridley
  class Node
    module DSL
      def node
        Ridley::Node
      end
    end

    include Ridley::Resource

    set_chef_id "name"
    set_chef_type "node"
    set_chef_json_class "Chef::Node"
    set_resource_path "nodes"

    attribute :name
    validates_presence_of :name

    attribute :description, default: String.new
    validates_presence_of :description

    # JW TODO: oh man. An attribute called attributes. Need to figure out how to
    # deal with this best.
    #
    # attribute :attributes, default: Hash.new
    # validates_presence_of :attributes

    attribute :overrides, default: Hash.new
    validates_presence_of :overrides

    attribute :defaults, default: Hash.new
    validates_presence_of :defaults

    attribute :run_list, default: Array.new
    validates_presence_of :run_list
  end
end
