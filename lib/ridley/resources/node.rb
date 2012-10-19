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
    attribute :automatic, default: HashWithIndifferentAccess.new
    attribute :normal, default: HashWithIndifferentAccess.new
    attribute :default, default: HashWithIndifferentAccess.new
    attribute :override, default: HashWithIndifferentAccess.new
    attribute :run_list, default: Array.new

    # @param [Hash] hash
    def automatic=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end

    # @param [Hash] hash
    def normal=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end

    # @param [Hash] hash
    def default=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end

    # @param [Hash] hash
    def override=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end

    # @param [Hash] hash
    def normal=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end

    # Set a node level normal attribute given the dotted path representation of the Chef
    # attribute and value.
    #
    # @note It is not possible to set any other attribute level on a node and have it persist after
    #   a Chef Run. This is because all other attribute levels are truncated at the start of a Chef Run. 
    # 
    # @example setting and saving a node level normal attribute
    #
    #   obj = node.find("jwinsor-1")
    #   obj.set_normal_attribute("my_app.billing.enabled", false)
    #   obj.save
    #
    # @param [String] key
    # @param [Object] value
    #
    # @return [HashWithIndifferentAccess]
    def set_attribute(key, value)
      attr_hash = HashWithIndifferentAccess.from_dotted_path(key, value)
      self.normal = self.normal.merge(attr_hash)
    end

    def eucalyptus?
      self.automatic.has_key?(:eucalyptus)
    end

    def ec2?
      self.automatic.has_key?(:ec2)
    end
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
