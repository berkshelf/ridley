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
      def best_connector_for(host)
        if connector_port_open?(host, DEFAULT_SSH_PORT)
          Ridley::HostConnector::SSH
        elsif connector_port_open?(host, DEFAULT_WINRM_PORT)
          Ridley::HostConnector::WinRM
        else
          raise Ridley::Errors::UnknownHostConnector, "No connection method available on #{host}"
        end
      end

      def connector_port_open?(host, port)
        Timeout::timeout(1) do
          begin
            socket = TCPSocket.new(host, port)
            socket.close
            true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            false
          end
        end
      rescue Timeout::Error
        false
      end
    end
  end
end
