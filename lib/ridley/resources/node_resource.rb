module Ridley 
  # @author Jamie Winsor <reset@riotgames.com>
  class NodeResource < Ridley::Resource
    class << self
      # @overload bootstrap(client, nodes, options = {})
      #   @param [Ridley::Client] client
      #   @param [Array<String>, String] nodes
      #   @param [Hash] ssh
      #     * :user (String) a shell user that will login to each node and perform the bootstrap command on (required)
      #     * :password (String) the password for the shell user that will perform the bootstrap
      #     * :keys (Array, String) an array of keys (or a single key) to authenticate the ssh user with instead of a password
      #     * :timeout (Float) [5.0] timeout value for SSH bootstrap
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
      #
      # @return [SSH::ResponseSet]
      def bootstrap(client, *args)
        options = args.extract_options!

        default_options = {
          server_url: client.server_url,
          validator_path: client.validator_path,
          validator_client: client.validator_client,
          encrypted_data_bag_secret_path: client.encrypted_data_bag_secret_path,
          ssh: client.ssh
        }

        options = default_options.merge(options)

        Bootstrapper.new(*args, options).run
      end

      # Merges the given data with the the data of the target node on the remote
      #
      # @param [Ridley::Client] client
      # @param [Ridley::NodeResource, String] target
      #   node or identifier of the node to merge
      #
      # @option options [Array] :run_list
      #   run list items to merge
      # @option options [Hash] :attributes
      #   attributes of normal precedence to merge
      #
      # @raise [Errors::HTTPNotFound]
      #   if the target node is not found
      #
      # @return [Ridley::NodeResource]
      def merge_data(client, target, options = {})
        find!(client, target).merge_data(options)
      end
    end

    set_chef_id "name"
    set_chef_type "node"
    set_chef_json_class "Chef::Node"
    set_resource_path "nodes"

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

    alias_method :normal_attributes=, :normal=
    alias_method :automatic_attributes=, :automatic=
    alias_method :default_attributes=, :default=
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
    #   obj.set_chef_attribute("my_app.billing.enabled", false)
    #   obj.save
    #
    # @param [String] key
    # @param [Object] value
    #
    # @return [Hashie::Mash]
    def set_chef_attribute(key, value)
      attr_hash = Hashie::Mash.from_dotted_path(key, value)
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
    # @param [Hash] options
    #   a hash of options to pass to {Ridley::SSH.start}
    #
    # @return [SSH::Response]
    def chef_client(options = {})
      options = client.ssh.merge(options)

      Ridley.log.debug "Running Chef Client on: #{self.public_hostname}"
      Ridley::SSH.start(self, options) do |ssh|
        ssh.run("sudo chef-client").first
      end
    end

    # Put the client's encrypted data bag secret onto the instantiated node. If no
    # encrypted data bag key path is set on the resource's client then nil will be
    # returned
    #
    # @param [Hash] options
    #   a hash of options to pass to {Ridley::SSH.start}
    #
    # @return [SSH::Response, nil]
    def put_secret(options = {})
      if client.encrypted_data_bag_secret_path.nil? ||
        !File.exists?(client.encrypted_data_bag_secret_path)

        return nil
      end

      options = client.ssh.merge(options)
      secret  = File.read(client.encrypted_data_bag_secret_path).chomp
      command = "echo '#{secret}' > /etc/chef/encrypted_data_bag_secret; chmod 0600 /etc/chef/encrypted_data_bag_secret"

      Ridley.log.debug "Writing Encrypted Data Bag Secret to: #{self.public_hostname}"
      Ridley::SSH.start(self, options) do |ssh|
        ssh.run(command).first
      end
    end

    # Merges the instaniated nodes data with the given data and updates
    # the remote with the merged results
    #
    # @option options [Array] :run_list
    #   run list items to merge
    # @option options [Hash] :attributes
    #   attributes of normal precedence to merge
    #
    # @return [Ridley::NodeResource]
    def merge_data(options = {})
      unless options[:run_list].nil?
        self.run_list = (self.run_list + Array(options[:run_list])).uniq
      end

      unless options[:attributes].nil?
        self.normal = self.normal.deep_merge(options[:attributes])
      end

      self.update
      self
    end
  end
end
