require 'socket'
require 'timeout'

module Ridley
  # @author Kyle Allan <kallan@riotgames.com>
  module HostConnector
    autoload :Response, 'ridley/host_connector/response'
    autoload :ResponseSet, 'ridley/host_connector/response_set'
    autoload :SSH, 'ridley/host_connector/ssh'
    autoload :WinRM, 'ridley/host_connector/winrm'

    DEFAULT_SSH_PORT   = 22.freeze
    DEFAULT_WINRM_PORT = 5985.freeze

    class << self
      # Create a new connection worker for the given host. An SSH or WinRM connection will be returned
      # depending on which ports are open on the target host.
      #
      # @param [String] host
      #   host to create a connector for
      #
      # @option options [Hash] ssh
      #   * :user (String) a shell user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the shell user that will perform the bootstrap
      #   * :keys (Array, String) an array of keys (or a single key) to authenticate the ssh user with instead of a password
      #   * :timeout (Float) [5.0] timeout value for SSH bootstrap
      # @option options [Hash] :winrm
      #   * :user (String) a user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the user that will perform the bootstrap
      #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on
      #
      # @return [SSH::Worker, WinRM::Worker]
      def new(host, options = {})
        HostConnector.best_connector_for(host, options) do |host_connector|
          host_connector::Worker.new(host, options)
        end
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
      # @return [Ridley::HostConnector] a class under Ridley::HostConnector
      def best_connector_for(host, options = {}, &block)
        ssh_port, winrm_port = parse_port_options(options)
        timeout = options[:ssh] && options[:ssh][:timeout]

        if connector_port_open?(host, winrm_port)
          host_connector = Ridley::HostConnector::WinRM
        elsif connector_port_open?(host, ssh_port, timeout)
          host_connector = Ridley::HostConnector::SSH
        else
          raise Ridley::Errors::HostConnectionError, "No available connection method available on #{host}."
        end

        if block_given?
          yield host_connector
        else
          host_connector
        end
      end

      # Checks to see if the given port is open for TCP connections
      # on the given host.
      #
      # @param  host [String]
      #   the host to attempt to connect to
      # @param  port [Fixnum]
      #   the port to attempt to connect on
      # @param  timeout [Float]
      #   the number of seconds to wait (default: 3)
      #
      # @return [Boolean]
      def connector_port_open?(host, port, timeout = nil)
        timeout ||= 3

        Timeout::timeout(timeout) do
          socket = TCPSocket.new(host, port)
          socket.close
        end

        true
      rescue Timeout::Error, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        false
      end

      # Parses the options Hash and returns an array of
      # [SSH_PORT, WINRM_PORT] used to attempt to connect to.
      #
      # @option options [Hash] :ssh
      #   * :port (Fixnum) the ssh port to connect on the node the bootstrap will be performed on (22)
      # @option options [Hash] :winrm
      #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
      #
      # @return [Array]
      def parse_port_options(options)
        ssh_port = options[:ssh][:port] if options[:ssh]
        winrm_port = options[:winrm][:port] if options[:winrm]
        [ssh_port || DEFAULT_SSH_PORT, winrm_port || DEFAULT_WINRM_PORT]
      end
    end
  end
end
