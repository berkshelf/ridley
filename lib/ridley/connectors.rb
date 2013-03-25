require 'socket'
require 'timeout'

module Ridley
  # @author Kyle Allan <kallan@riotgames.com>
  module Connectors
    autoload :SSH, 'ridley/connectors/ssh'
    autoload :WinRM, 'ridley/connectors/winrm'

    DEFAULT_SSH_PORT   = 22.freeze
    DEFAULT_WINRM_PORT = 5985.freeze

    class << self
      def best_connector_for(host)
        if default_connector_port_open?(host, DEFAULT_SSH_PORT)
          :SSH
        elsif default_connector_port_open?(host, DEFAULT_WINRM_PORT)
          :WinRM
        else
          raise Ridley::Errors::UnknownConnector, "No connection method available on #{host}"
        end
      end

      def default_connector_port_open?(host, port)
        Timeout::timeout(1) do
          begin
            socket = TCPSocket.new(host, port)
            socket.close
            true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            false
          end
        end
      end
    end
  end
end