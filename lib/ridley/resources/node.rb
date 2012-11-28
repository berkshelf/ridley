module Ridley 
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Node
    class << self
      # @overload bootstrap(connection, nodes, options = {})
      #   @param [Ridley::Connection] connection
      #   @param [Array<String>, String] nodes
      #   @option options [String] :ssh_user
      #   @option options [String] :ssh_password
      #   @option options [Array<String>, String] :ssh_keys
      #   @option options [Float] :ssh_timeout
      #     timeout value for SSH bootstrap (default: 1.5)
      #   @option options [String] :validator_client
      #   @option options [String] :validator_path
      #     filepath to the validator used to bootstrap the node (required)
      #   @option options [String] :bootstrap_proxy
      #     URL to a proxy server to bootstrap through (default: nil)
      #   @option options [String] :encrypted_data_bag_secret_path
      #     filepath on your host machine to your organizations encrypted data bag secret (default: nil)
      #   @option options [Hash] :hints
      #     a hash of Ohai hints to place on the bootstrapped node (default: Hash.new)
      #   @option options [Hash] :attributes
      #     a hash of attributes to use in the first Chef run (default: Hash.new)
      #   @option options [Array] :run_list
      #     an initial run list to bootstrap with (default: Array.new)
      #   @option options [String] :chef_version
      #     version of Chef to install on the node (default: {Ridley::CHEF_VERSION})
      #   @option options [String] :environment
      #     environment to join the node to (default: '_default')
      #   @option options [Boolean] :sudo
      #     bootstrap with sudo (default: true)
      #   @option options [String] :template
      #     bootstrap template to use (default: omnibus)
      def bootstrap(connection, *args)
        options = args.extract_options!

        default_options = {
          server_url: connection.server_url,
          ssh_user: connection.ssh[:user],
          ssh_password: connection.ssh[:password],
          ssh_keys: connection.ssh[:keys],
          ssh_timeout: connection.ssh[:timeout],
          validator_path: connection.validator_path,
          validator_client: connection.validator_client,
          encrypted_data_bag_secret_path: connection.encrypted_data_bag_secret_path
        }

        options = default_options.merge(options)

        Bootstrapper.new(*args, options).run
      end
    end

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

    alias_method :normal_attributes, :normal
    alias_method :automatic_attributes, :automatic
    alias_method :default_attributes, :default
    alias_method :override_attributes, :override

    # @param [Hash] hash
    def normal=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end
    alias_method :normal_attributes=, :normal=

    # @param [Hash] hash
    def automatic=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end
    alias_method :automatic_attributes=, :automatic=

    # @param [Hash] hash
    def default=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end
    alias_method :default_attributes=, :default=

    # @param [Hash] hash
    def override=(hash)
      super(HashWithIndifferentAccess.new(hash))
    end
    alias_method :override_attributes=, :override=

    # Set a node level normal attribute given the dotted path representation of the Chef
    # attribute and value.
    #
    # @note It is not possible to set any other attribute level on a node and have it persist after
    #   a Chef Run. This is because all other attribute levels are truncated at the start of a Chef Run. 
    # 
    # @example setting and saving a node level normal attribute
    #
    #   obj = node.find("jwinsor-1")
    #   obj.set_attribute("my_app.billing.enabled", false)
    #   obj.save
    #
    # @param [String] key
    # @param [Object] value
    #
    # @return [HashWithIndifferentAccess]
    def set_attribute(key, value)
      attr_hash = HashWithIndifferentAccess.from_dotted_path(key, value)
      self.normal = self.normal.deep_merge(attr_hash)
    end

    # Returns the public hostname of the instantiated node. This hostname should be used for
    # public communications to the node.
    #
    # @example
    #   node.public_hostname => "reset.riotgames.com"
    #
    # @return [String]
    def public_hostname
      self.cloud? ? self.automatic[:cloud][:public_hostname] : self.automatic[:fqdn]
    end

    # Returns the public IPv4 address of the instantiated node. This ip address should be
    # used for public communications to the node.
    #
    # @example
    #   node.public_ipv4 => "10.33.33.1"
    #
    # @return [String]
    def public_ipv4
      self.cloud? ? self.automatic[:cloud][:public_ipv4] : self.automatic[:ipaddress]
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

    # Run Chef-Client on the instantiated node
    #
    # @return [SSH::Response]
    def chef_client
      Ridley::SSH.start(self, connection.ssh) do |ssh|
        ssh.run("sudo chef-client").first
      end
    end
  end
  
  module DSL
    # Coerces instance functions into class functions on Ridley::Node. This coercion
    # sends an instance of the including class along to the class function.
    #
    # @see Ridley::ChainLink
    #
    # @return [Ridley::ChainLink]
    #   a context object to delegate instance functions to class functions on Ridley::Node
    def node
      ChainLink.new(self, Ridley::Node)
    end
  end
end
