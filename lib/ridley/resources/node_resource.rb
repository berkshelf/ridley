module Ridley
  class NodeResource < Ridley::Resource
    include Ridley::Logging

    set_resource_path "nodes"
    represented_by Ridley::NodeObject

    attr_reader :server_url
    attr_reader :validator_path
    attr_reader :validator_client
    attr_reader :encrypted_data_bag_secret
    attr_reader :ssh
    attr_reader :winrm
    attr_reader :chef_version

    finalizer :finalize_callback

    # @param [Celluloid::Registry] connection_registry
    #
    # @option options [String] :server_url
    #   URL to the Chef API
    # @option options [Hash] ssh
    #   * :user (String) a shell user that will login to each node and perform the bootstrap command on
    #   * :password (String) the password for the shell user that will perform the bootstrap
    #   * :keys (Array, String) an array of keys (or a single key) to authenticate the ssh user with instead of a password
    #   * :timeout (Float) [5.0] timeout value for SSH bootstrap
    # @option options [Hash] :winrm
    #   * :user (String) a user that will login to each node and perform the bootstrap command on
    #   * :password (String) the password for the user that will perform the bootstrap
    #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on
    # @option options [String] :validator_client
    # @option options [String] :validator_path
    #   filepath to the validator used to bootstrap the node
    # @option options [String] :encrypted_data_bag_secret
    #   your organizations encrypted data bag secret
    # @option options [String] :chef_version
    #   version of Chef to install on the node (default: nil)
    def initialize(connection_registry, options = {})
      super(connection_registry)
      @server_url                = options[:server_url]
      @validator_path            = options[:validator_path]
      @validator_client          = options[:validator_client]
      @encrypted_data_bag_secret = options[:encrypted_data_bag_secret]
      @ssh                       = options[:ssh]
      @winrm                     = options[:winrm]
      @chef_version              = options[:chef_version]
      @host_commander            = HostCommander.new_link
    end

    # @param [String] host
    #
    # @option options [Hash] ssh
    #   * :user (String) a shell user that will login to each node and perform the bootstrap command on (required)
    #   * :password (String) the password for the shell user that will perform the bootstrap
    #   * :keys (Array, String) an array of keys (or a single key) to authenticate the ssh user with instead of a password
    #   * :timeout (Float) [5.0] timeout value for SSH bootstrap
    # @option options [Hash] :winrm
    #   * :user (String) a user that will login to each node and perform the bootstrap command on (required)
    #   * :password (String) the password for the user that will perform the bootstrap
    #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
    # @option options [String] :validator_client
    # @option options [String] :validator_path
    #   filepath to the validator used to bootstrap the node (required)
    # @option options [String] :bootstrap_proxy
    #   URL to a proxy server to bootstrap through (default: nil)
    # @option options [String] :encrypted_data_bag_secret_path
    #   filepath on your host machine to your organizations encrypted data bag secret (default: nil)
    # @option options [Hash] :hints
    #   a hash of Ohai hints to place on the bootstrapped node (default: Hash.new)
    # @option options [Hash] :attributes
    #   a hash of attributes to use in the first Chef run (default: Hash.new)
    # @option options [Array] :run_list
    #   an initial run list to bootstrap with (default: Array.new)
    # @option options [String] :chef_version
    #   version of Chef to install on the node (default: nil)
    # @option options [String] :environment
    #   environment to join the node to (default: '_default')
    # @option options [Boolean] :sudo
    #   bootstrap with sudo (default: true)
    # @option options [String] :template
    #   bootstrap template to use (default: omnibus)
    #
    # @return [HostConnector::Response]
    def bootstrap(host, options = {})
      options = options.reverse_merge(
        server_url: server_url,
        validator_path: validator_path,
        validator_client: validator_client,
        encrypted_data_bag_secret: encrypted_data_bag_secret,
        ssh: ssh,
        winrm: winrm,
        chef_version: chef_version
      )

      host_commander.bootstrap(host, options)
    end

    # Executes a Chef run using the best worker available for the given
    # host.
    #
    # @param [String] host
    #
    # @return [HostConnector::Response]
    def chef_run(host)
      host_commander.chef_client(host, ssh: ssh, winrm: winrm)
    rescue Errors::HostConnectionError => ex
      abort(ex)
    end

    # Puts a secret on the host using the best worker available for
    # the given host.
    #
    # @param [String] host
    #
    # @return [HostConnector::Response]
    def put_secret(host)
      host_commander.put_secret(host, encrypted_data_bag_secret, ssh: ssh, winrm: winrm)
    end

    # Executes an arbitrary ruby script using the best worker available
    # for the given host.
    #
    # @param [String] host
    # @param [Array<String>] command_lines
    #
    # @return [HostConnector::Response]
    def ruby_script(host, command_lines)
      host_commander.ruby_script(host, command_lines, ssh: ssh, winrm: winrm)
    end

    # Executes the given command on a node using the best worker
    # available for the given host.
    #
    # @param [String] host
    # @param [String] command
    #
    # @return [HostConnector::Response]
    def run(host, command)
      host_commander.run(host, command, ssh: ssh, winrm: winrm)
    end
    alias_method :execute_command, :run

    # Executes the given command on a node using a platform specific
    # command.
    #
    # @param [String] host
    # @param [Hash] commands
    #
    # @example
    #   platform_specific_run("host.example.com", linux: "hostname -f", windows: "echo %COMPUTERNAME%")
    #
    # @return [HostConnector::Response]
    def platform_specific_run(host, commands)
      case (type = host_commander.connector_for(host, ssh: ssh, winrm: winrm))
      when HostConnector::SSH
        raise Errors::CommandNotProvided.new(:ssh) unless commands[:ssh] and !commands[:ssh].empty?
        run(host, commands[:ssh])
      when HostConnector::WinRM
        raise Errors::CommandNotProvided.new(:winrm) unless commands[:winrm] and !commands[:winrm].empty?
        run(host, commands[:winrm])
      else
        raise RuntimeError, "#{type.class.to_s} is not a supported connector for #{self.class}##{__method__}"
      end
    end
    alias_method :execute_platform_specific_command, :platform_specific_run

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

    # Uninstall Chef from a node
    #
    # @param [String] host
    #   the host to perform the action on
    #
    # @option options [Boolena] :skip_chef (false)
    #   skip removal of the Chef package and the contents of the installation
    #   directory. Setting this to true will only remove any data and configurations
    #   generated by running Chef client.
    # @option options [Hash] :ssh
    #   * :user (String) a shell user that will login to each node and perform the bootstrap command on
    #   * :password (String) the password for the shell user that will perform the bootstrap
    #   * :keys (Array, String) an array of key(s) to authenticate the ssh user with instead of a password
    #   * :timeout (Float) timeout value for SSH bootstrap (5.0)
    #   * :sudo (Boolean) run as sudo (true)
    # @option options [Hash] :winrm
    #   * :user (String) a user that will login to each node and perform the bootstrap command on
    #   * :password (String) the password for the user that will perform the bootstrap (required)
    #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
    #
    # @return [HostConnector::Response]
    def uninstall_chef(host, options = {})
      options = options.reverse_merge(ssh: ssh, winrm: winrm)
      host_commander.uninstall_chef(host, options)
    end

    private

      # @return [Ridley::HostCommander]
      attr_reader :host_commander

      def finalize_callback
        @host_commander.terminate if @host_commander && @host_commander.alive?
      end
  end
end
