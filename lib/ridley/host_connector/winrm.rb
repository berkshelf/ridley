module Ridley
  module HostConnector
    # @author Kyle Allan <kallan@riotgames.com>
    class WinRM
      require_relative 'winrm/command_uploader'
      require_relative 'winrm/worker'

      class << self
        # @param [Ridley::NodeResource, Array<Ridley::NodeResource>] nodes
        # @param [Hash] options
        def start(nodes, options = {}, &block)
          runner = new(nodes, options)
          result = yield runner
          runner.terminate

          result
        ensure
          runner.terminate if runner && runner.alive?
        end
      end

      include Celluloid
      include Celluloid::Logger

      attr_reader :nodes
      attr_reader :options

      # @param [Ridley::NodeResource, Array<Ridley::NodeResource>] nodes
      # @param [Hash] options
      def initialize(nodes, options = {})
        @nodes = Array(nodes)
        @options = options
      end

      # @param [String] command
      #
      # @return [Array]
      def run(command)
        workers = Array.new
        futures = self.nodes.collect do |node|
          workers << worker = Worker.new(node.public_hostname, self.options.freeze)
          worker.future.run(command)
        end

        Ridley::HostConnector::ResponseSet.new.tap do |response_set|
          futures.each do |future|
            status, response = future.value
            response_set.add_response(response)
          end
        end
      ensure
        workers.map(&:terminate)
      end
    end
  end
end
