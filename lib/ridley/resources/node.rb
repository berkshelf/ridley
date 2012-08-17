module Ridley
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
end
