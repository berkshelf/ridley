require 'socket'
require 'timeout'

module Ridley
  class ConnectorSupervisor < ::Celluloid::SupervisionGroup
    def initialize(registry)
      super(registry)
      supervise_as :ssh, HostConnector::SSH
      supervise_as :winrm, HostConnector::WinRM
    end
  end

  class HostCommander
    class << self
      # Checks to see if the given port is open for TCP connections
      # on the given host.
      #
      # @param  host [String]
      #   the host to attempt to connect to
      # @param  port [Fixnum]
      #   the port to attempt to connect on
      # @param  timeout [Float]
      #   the number of seconds to wait (default: {PORT_CHECK_TIMEOUT})
      #
      # @return [Boolean]
      def connector_port_open?(host, port, timeout = nil)
        Timeout.timeout(timeout || PORT_CHECK_TIMEOUT) { TCPSocket.new(host, port).close; true }
      rescue Timeout::Error, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::EADDRNOTAVAIL => ex
        false
      end
    end

    include Celluloid
    include Ridley::Logging

    PORT_CHECK_TIMEOUT = 3

    def initialize
      @connector_registry   = Celluloid::Registry.new
      @connector_supervisor = ConnectorSupervisor.new_link(@connector_registry)
    end

    def run(host, command, options = {})
      execute(__method__, host, command, options)
    end

    def bootstrap(host, options = {})
      execute(__method__, host, options)
    end

    # Executes a chef-client command on the nodes
    #
    # @return [#run]
    def chef_client(host, options = {})
      execute(__method__, host, options)
    end

    # Writes the given encrypted data bag secret to the node
    #
    # @param [String] secret
    #   your organization's encrypted data bag secret
    #
    # @return [#run]
    def put_secret(host, secret, options = {})
      execute(__method__, host, secret, options)
    end

    # Executes a provided Ruby script in the embedded Ruby installation
    #
    # @param [Array<String>] command_lines
    #   An Array of lines of the command to be executed
    #
    # @return [#run]
    def ruby_script(host, command_lines, options = {})
      execute(__method__, host, command_lines, options)
    end

    private

      def execute(method, host, *args)
        options = args.last.is_a?(Hash) ? args.pop : Hash.new

        connector, connector_opts = connector_for(host, options)
        connector.send(method, host, *args, connector_opts)
      rescue Errors::HostConnectionError => ex
        abort(ex)
      end

      # Finds and returns the best HostConnector for a given host
      #
      # @param  host [String]
      #   the host to attempt to connect to
      # @option options [Hash] :ssh
      #   * :port (Fixnum) the ssh port to connect on the node the bootstrap will be performed on (22)
      #   * :timeout (Float) [5.0] timeout value for testing SSH connection
      # @option options [Hash] :winrm
      #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
      # @param block [Proc]
      #   an optional block that is yielded the best HostConnector
      #
      # @return [Symbol]
      def connector_for(host, options = {})
        options = options.reverse_merge(ssh: Hash.new, winrm: Hash.new)
        options[:ssh][:port]   ||= HostConnector::SSH::DEFAULT_PORT
        options[:winrm][:port] ||= HostConnector::WinRM::DEFAULT_PORT

        if self.class.connector_port_open?(host, options[:winrm][:port])
          [ winrm, options[:winrm] ]
        elsif self.class.connector_port_open?(host, options[:ssh][:port], options[:ssh][:timeout])
          [ ssh, options[:ssh] ]
        else
          raise Errors::HostConnectionError, "No connector ports open on '#{host}'"
        end
      end

      def ssh
        @connector_registry[:ssh]
      end

      def winrm
        @connector_registry[:winrm]
      end
  end
end
