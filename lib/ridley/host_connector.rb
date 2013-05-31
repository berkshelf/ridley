module Ridley
  # @author Kyle Allan <kallan@riotgames.com>
  module HostConnector
    class Base
      include Celluloid
      include Ridley::Logging

      def run(host, command, options = {})
        raise RuntimeError, "abstract function: must be implemented on includer"
      end

      def bootstrap(host, options = {})
        raise RuntimeError, "abstract function: must be implemented on includer"
      end

      # Executes a chef-client command on the nodes
      #
      # @return [#run]
      def chef_client(host, options = {})
        raise RuntimeError, "abstract function: must be implemented on includer"
      end

      # Writes the given encrypted data bag secret to the node
      #
      # @param [String] secret
      #   your organization's encrypted data bag secret
      #
      # @return [#run]
      def put_secret(host, secret, options = {})
        raise RuntimeError, "abstract function: must be implemented on includer"
      end

      # Executes a provided Ruby script in the embedded Ruby installation
      #
      # @param [Array<String>] command_lines
      #   An Array of lines of the command to be executed
      #
      # @return [#run]
      def ruby_script(host, command_lines, options = {})
        raise RuntimeError, "abstract function: must be implemented on includer"
      end
    end

    require_relative 'host_connector/response'
    require_relative 'host_connector/ssh'
    require_relative 'host_connector/winrm'
  end
end
