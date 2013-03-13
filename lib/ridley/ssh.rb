require 'net/ssh'

module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class SSH
    autoload :Response, 'ridley/ssh/response'
    autoload :ResponseSet, 'ridley/ssh/response_set'
    autoload :Worker, 'ridley/ssh/worker'

    class << self
      # @param [Ridley::NodeResource, Array<Ridley::NodeResource>] nodes
      # @param [Hash] options
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

    # @param [Ridley::NodeResource, Array<Ridley::NodeResource>] nodes
    # @param [Hash] options
    #   @see Net::SSH
    def initialize(nodes, options = {})
      @nodes   = Array(nodes)
      @options = options
    end

    # @param [String] command
    #
    # @return [Array]
    def run(command)
      workers = Array.new
      futures = self.nodes.collect do |node|
        workers << worker = Worker.new_link(self.options.freeze)
        worker.future.run(node.public_hostname, command)
      end

      ResponseSet.new.tap do |response_set|
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
