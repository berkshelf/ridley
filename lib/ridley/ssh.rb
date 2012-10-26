require 'net/ssh'

module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class SSH
    autoload :Response, 'ridley/ssh/response'
    autoload :ResponseSet, 'ridley/ssh/response_set'
    autoload :Worker, 'ridley/ssh/worker'

    class << self
      # @param [Ridley::Node, Array<Ridley::Node>] nodes
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

    # @param [Ridley::Node, Array<Ridley::Node>] nodes
    # @param [Hash] options
    #   @see Net::SSH
    def initialize(nodes, options = {})
      @nodes   = nodes
      @options = options

      self.options[:timeout] ||= 1.5
    end

    # @return [Array<SSH::Worker>]
    def workers
      @workers ||= Array(nodes).collect do |node|
        Worker.new_link(current_actor, node.public_hostname, options)
      end
    end

    # @param [String] command
    #
    # @return [Array]
    def run(command)
      workers.collect { |worker| worker.async.run(command) }

      ResponseSet.new.tap do |responses|
        until responses.length == workers.length
          receive { |msg|
            status, response = msg
            
            case status
            when :ok
              responses.add_ok(response)
            when :error
              responses.add_error(response)
            else
              error "SSH Failure: #{command}. terminating..."
              terminate
            end
          }
        end
      end
    end

    def finalize
      workers.collect(&:terminate)
    end
  end
end
