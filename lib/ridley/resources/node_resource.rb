module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class NodeResource < Ridley::Resource
    include Ridley::Logging

    set_chef_type "node"
    set_chef_json_class "Chef::Node"
    set_resource_path "nodes"
    represented_by Ridley::NodeObject

    # @overload bootstrap(nodes, options = {})
    #   @param [Array<String>, String] nodes
    #   @param [Hash] ssh
    #     * :user (String) a shell user that will login to each node and perform the bootstrap command on (required)
    #     * :password (String) the password for the shell user that will perform the bootstrap
    #     * :keys (Array, String) an array of keys (or a single key) to authenticate the ssh user with instead of a password
    #     * :timeout (Float) [5.0] timeout value for SSH bootstrap
    #   @option options [Hash] :winrm
    #     * :user (String) a user that will login to each node and perform the bootstrap command on (required)
    #     * :password (String) the password for the user that will perform the bootstrap
    #     * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
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
    #     version of Chef to install on the node (default: nil)
    #   @option options [String] :environment
    #     environment to join the node to (default: '_default')
    #   @option options [Boolean] :sudo
    #     bootstrap with sudo (default: true)
    #   @option options [String] :template
    #     bootstrap template to use (default: omnibus)
    #
    # @return [SSH::ResponseSet]
    def bootstrap(*args)
      options = args.extract_options!

      default_options = {
        server_url: client.server_url,
        validator_path: client.validator_path,
        validator_client: client.validator_client,
        encrypted_data_bag_secret_path: client.encrypted_data_bag_secret_path,
        ssh: client.ssh,
        winrm: client.winrm,
        chef_version: client.chef_version
      }

      options = default_options.merge(options)
      Bootstrapper.new(args, options).run
    end

    # Executes a Chef run using the best worker available for the given
    # host.
    #
    # @param [Ridley::Client] client
    # @param [String] host
    #
    # @return [HostConnector::Response]
    def chef_run(client, host)
      worker = configured_worker_for(client, host)
      worker.chef_client
    ensure
      worker.terminate if worker && worker.alive?
    end

    # Puts a secret on the host using the best worker available for
    # the given host.
    #
    # @param [Ridley::Client] client
    # @param [String] host
    # @param [String] encrypted_data_bag_secret_path
    #
    # @return [HostConnector::Response]
    def put_secret(client, host, encrypted_data_bag_secret_path)
      worker = configured_worker_for(client, host)
      worker.put_secret(encrypted_data_bag_secret_path)
    ensure
      worker.terminate if worker && worker.alive?
    end

    # Executes an arbitrary ruby script using the best worker available
    # for the given host.
    #
    # @param [Ridley::Client] client
    # @param [String] host
    # @param [Array<String>] command_lines
    #
    # @return [HostConnector::Response]
    def ruby_script(client, host, command_lines)
      worker = configured_worker_for(client, host)
      worker.ruby_script(command_lines)
    ensure
      worker.terminate if worker && worker.alive?
    end

    # Executes the given command on a node using the best worker
    # available for the given host.
    #
    # @param [Ridley::Client] client
    # @param [String] host
    # @param [String] command
    #
    # @return [Array<Symbol, HostConnector::Response>]
    def execute_command(client, host, command)
      worker = configured_worker_for(client, host)
      worker.run(command)
    ensure
      worker.terminate if worker && worker.alive?
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
    # @raise [Errors::HTTPNotFound]
    #   if the target node is not found
    #
    # @return [Ridley::NodeResource]
    def merge_data(target, options = {})
      find!(target).merge_data(options)
    end

    private
      # @param [Ridley::Client] client
      # @param [String] host
      #
      # @return [SSH::Worker, WinRM::Worker]
      def configured_worker_for(client, host)
        connector_options = Hash.new
        connector_options[:ssh] = client.ssh
        connector_options[:winrm] = client.winrm

        HostConnector.best_connector_for(host, connector_options) do |host_connector|
          host_connector::Worker.new(host, connector_options)
        end
      end
  end
end
