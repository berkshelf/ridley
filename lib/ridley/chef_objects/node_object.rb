module Ridley
  class NodeObject < Ridley::ChefObject
    set_chef_id "name"
    set_chef_type "node"
    set_chef_json_class "Chef::Node"

    attribute :name,
      required: true

    attribute :chef_environment,
      default: "_default"

    attribute :automatic,
      default: Hashie::Mash.new

    attribute :normal,
      default: Hashie::Mash.new

    attribute :default,
      default: Hashie::Mash.new

    attribute :override,
      default: Hashie::Mash.new

    attribute :run_list,
      default: Array.new

    alias_method :normal_attributes, :normal
    alias_method :automatic_attributes, :automatic
    alias_method :default_attributes, :default
    alias_method :override_attributes, :override

    # A merged hash containing a deep merge of all of the attributes respecting the node attribute
    # precedence level.
    #
    # @return [hashie::Mash]
    def chef_attributes
      default.merge(normal.merge(override.merge(automatic)))
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
    #   obj.set_chef_attribute("my_app.billing.enabled", false)
    #   obj.save
    #
    # @param [String] key
    #   dotted path to key to be unset
    # @param [Object] value
    #
    # @return [Hashie::Mash]
    def set_chef_attribute(key, value)
      attr_hash   = Hashie::Mash.from_dotted_path(key, value)
      self.normal = self.normal.deep_merge(attr_hash)
    end

    # Unset a node level normal attribute given the dotted path representation of the Chef
    # attribute and value.
    #
    # @example unsetting and saving a node level normal attribute
    #
    #   obj = node.find("foonode")
    #   obj.unset_chef_attribute("my_app.service_one.service_state")
    #   obj.save
    #
    # @param [String] key
    #   dotted path to key to be unset
    #
    # @return [Hashie::Mash]
    def unset_chef_attribute(key)
      keys = key.split(".")
      leaf_key = keys.pop
      attributes = keys.inject(self.normal) do |attributes, key|
        if attributes[key] && attributes[key].kind_of?(Hashie::Mash)
          attributes = attributes[key]
        else 
          return self.normal
        end
      end

      attributes.delete(leaf_key)
      return self.normal
    end

    # Returns the public hostname of the instantiated node. This hostname should be used for
    # public communications to the node.
    #
    # @example
    #   node.public_hostname => "reset.riotgames.com"
    #
    # @return [String]
    def public_hostname
      self.cloud? ? self.automatic[:cloud][:public_hostname] || self.automatic[:fqdn] : self.automatic[:fqdn]
    end

    # Returns the public IPv4 address of the instantiated node. This ip address should be
    # used for public communications to the node.
    #
    # @example
    #   node.public_ipv4 => "10.33.33.1"
    #
    # @return [String]
    def public_ipv4
      self.cloud? ? self.automatic[:cloud][:public_ipv4] || self.automatic[:ipaddress] : self.automatic[:ipaddress]
    end
    alias_method :public_ipaddress, :public_ipv4

    # Returns the cloud provider of the instantiated node. If the node is not identified as
    # a cloud node, then nil is returned.
    #
    # @example
    #   node_1.cloud_provider => "eucalyptus"
    #   node_2.cloud_provider => "ec2"
    #   node_3.cloud_provider => "rackspace"
    #   node_4.cloud_provider => nil
    #
    # @return [nil, String]
    def cloud_provider
      self.cloud? ? self.automatic[:cloud][:provider] : nil
    end

    # Returns true if the node is identified as a cloud node.
    #
    # @return [Boolean]
    def cloud?
      self.automatic.has_key?(:cloud)
    end

    # Returns true if the node is identified as a cloud node using the eucalyptus provider.
    #
    # @return [Boolean]
    def eucalyptus?
      self.cloud_provider == "eucalyptus"
    end

    # Returns true if the node is identified as a cloud node using the ec2 provider.
    #
    # @return [Boolean]
    def ec2?
      self.cloud_provider == "ec2"
    end

    # Returns true if the node is identified as a cloud node using the rackspace provider.
    #
    # @return [Boolean]
    def rackspace?
      self.cloud_provider == "rackspace"
    end

    # Merges the instaniated nodes data with the given data and updates
    # the remote with the merged results
    #
    # @option options [Array] :run_list
    #   run list items to merge
    # @option options [Hash] :attributes
    #   attributes of normal precedence to merge
    #
    # @return [Ridley::NodeObject]
    def merge_data(options = {})
      new_run_list   = Array(options[:run_list])
      new_attributes = options[:attributes]

      unless new_run_list.empty?
        self.run_list = self.run_list | new_run_list
      end

      unless new_attributes.nil?
        self.normal = self.normal.deep_merge(new_attributes)
      end

      self
    end
  end
end
