require 'erubis'

module Ridley
  class Bootstrapper
    # @author Jamie Winsor <reset@riotgames.com>
    class Context
      class << self
        # @param [String] host
        # @option options [Hash] :ssh
        #   * :user (String) a shell user that will login to each node and perform the bootstrap command on (required)
        #   * :password (String) the password for the shell user that will perform the bootstrap
        #   * :port (Fixnum) the ssh port to connect on the node the bootstrap will be performed on (22)
        #   * :keys (Array, String) an array of keys (or a single key) to authenticate the ssh user with instead of a password
        #   * :timeout (Float) [5.0] timeout value for SSH bootstrap
        # @option options [Hash] :winrm
        #   * :user (String) a user that will login to each node and perform the bootstrap command on (required)
        #   * :password (String) the password for the user that will perform the bootstrap
        #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
        # @option options [String] :validator_client
        # @option options [String] :validator_path
        #   filepath to the validator used to bootstrap the node (required)
        # @option options [String] :bootstrap_proxy (nil)
        #   URL to a proxy server to bootstrap through
        # @option options [String] :encrypted_data_bag_secret_path (nil)
        #   filepath on your host machine to your organizations encrypted data bag secret
        # @option options [Hash] :hints (Hash.new)
        #   a hash of Ohai hints to place on the bootstrapped node
        # @option options [Hash] :attributes (Hash.new)
        #   a hash of attributes to use in the first Chef run
        # @option options [Array] :run_list (Array.new)
        #   an initial run list to bootstrap with
        # @option options [String] :chef_version (nil)
        #   version of Chef to install on the node
        # @option options [String] :environment ('_default')
        #   environment to join the node to
        # @option options [Boolean] :sudo (true)
        #   bootstrap with sudo (default: true)
        # @option options [String] :template ('omnibus')
        #   bootstrap template to use
        #
        # @raise [Errors::HostConnectionError] if a node is unreachable
        def create(host, options = {})
          host_connector = HostConnector.best_connector_for(host, options)
          template_binding = case host_connector.to_s
          when Ridley::HostConnector::SSH.to_s
            Ridley::UnixTemplateBinding.new(options)
          when Ridley::HostConnector::WinRM.to_s
            Ridley::WindowsTemplateBinding.new(options)
          else
            raise Ridley::Errors::HostConnectionError, "Cannot find an appropriate Template Binding for an unknown connector."
          end
          new(host, host_connector, template_binding)
        end
      end

      # @return [String]
      attr_reader :host
      # @return [Ridley::HostConnector]
      attr_reader :host_connector
      # @return [Ridley::Binding]
      attr_reader :template_binding

      # @param [String] host
      #   name of the node as identified in Chef
      # @param [Ridley::HostConnector] host_connector
      #   either the SSH or WinRM Connector class
      # @param [Ridley::Binding] template_binding
      #   an instance of either the UnixTemplateBinding or WindowsTemplateBinding class
      def initialize(host, host_connector, template_binding)
        @host                           = host
        @host_connector                 = host_connector
        @template_binding               = template_binding
      end

      # @return [String]
      def clean_command
        "rm /etc/chef/first-boot.json; rm /etc/chef/validation.pem"
      end
    end
  end
end
