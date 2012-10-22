require 'net/ssh'

module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class SSH
    autoload :Response, 'ridley/ssh/response'
    autoload :Worker, 'ridley/ssh/worker'

    include Celluloid
    include Celluloid::Logger

    attr_reader :nodes
    attr_reader :user
    attr_reader :options

    # @param [Ridley::Node, Array<Ridley::Node>] nodes
    # @param [String] user
    # @param [Hash] options
    #   @see Net::SSH
    def initialize(nodes, user, options = {})
      @nodes   = nodes
      @user    = user
      @options = options

      self.options[:timeout] ||= 1.5
    end

    # @return [Array<SSH::Worker>]
    def workers
      @workers ||= Array(nodes).collect do |node|
        Worker.new_link(current_actor, node.public_hostname, user, options)
      end
    end

    # @param [String] command
    #
    # @return [Array]
    def run(command)
      workers.collect { |worker| worker.async.run(command) }

      [].tap do |responses|
        until responses.length == workers.length
          receive { |msg|
            status, response = msg
            
            case status
            when :ok, :error
              responses << msg
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
