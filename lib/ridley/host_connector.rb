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
      # Finds and returns the best HostConnector for a given host
      #
      # @param  host [String]
      #   the host to attempt to connect to
      # @option options [Hash] :ssh
      #   * :port (Fixnum) the ssh port to connect on the node the bootstrap will be performed on (22)
      # @option options [Hash] :winrm
      #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
      #
      # @return [Ridley::HostConnector] a class under Ridley::HostConnector
      def best_connector_for(host, options = {})
        ssh_port, winrm_port = parse_port_options(options)
        if connector_port_open?(host, ssh_port)
          Ridley::HostConnector::SSH
        elsif connector_port_open?(host, winrm_port)
          Ridley::HostConnector::WinRM
        else
          raise Ridley::Errors::HostConnectionError, "No available connection method available on #{host}."
        end
      end

      # Checks to see if the given port is open for TCP connections
      # on the given host.
      #
      # @param  host [String]
      #   the host to attempt to connect to
      # @param  port [Fixnum]
      #   the port to attempt to connect on
      #
      # @return [Boolean]
      def connector_port_open?(host, port)
        Timeout::timeout(1) do
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
