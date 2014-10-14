module Ridley
  class NodeResource < Ridley::Resource
    include Ridley::Logging

    set_resource_path "nodes"
    represented_by Ridley::NodeObject

    # @param [Celluloid::Registry] connection_registry
    def initialize(connection_registry, options = {})
      super(connection_registry)
    end

    # Merges the given data with the the data of the target node on the remote
    #
    # @param [Ridley::NodeResource, String] target
    #   node or identifier of the node to merge
    #
    # @option options [Array] :run_list
    #   run list items to merge
    # @option options [Hash] :attributes
    #   attributes of normal precedence to merge
    #
    # @raise [Errors::ResourceNotFound]
    #   if the target node is not found
    #
    # @return [Ridley::NodeObject]
    def merge_data(target, options = {})
      unless node = find(target)
        abort Errors::ResourceNotFound.new
      end

      update(node.merge_data(options))
    end
  end
end
