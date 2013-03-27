require 'winrm'

module Ridley
  module HostConnector
    # @author Kyle Allan <kallan@riotgames.com>
    class WinRM
      autoload :Worker, 'ridley/host_connector/winrm/worker'

      class << self
        def start(nodes, options = {}, &block)
          runner = new(nodes, options)
          result = yield runner
          runner.terminate

          result
        end
      end

      include Celluloid
      include Celluloid::Logger

      attr_reader :nodes
      attr_reader :options

      def initialize(nodes, options = {})
        @nodes = Array(nodes)
        @options = options
      end

      def run(command)
        workers = Array.new
        futures = self.nodes.collect do |node|
          workers << worker = Worker.new_link(node.public_hostname, self.options.freeze)
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
