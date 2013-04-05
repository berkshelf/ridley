require 'net/ssh'

module Ridley
  module HostConnector
    # @author Jamie Winsor <reset@riotgames.com>
    class SSH
      autoload :Worker, 'ridley/host_connector/ssh/worker'

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
          workers << worker = Worker.new(node.public_hostname, self.options.freeze)
          worker.future.run(command)
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

      # Executes a chef-client command on the nodes
      # 
      # @return [#run]
      def chef_client
        command = "chef-client"
        if self.options[:ssh] && self.options[:ssh][:sudo]
          command = "sudo #{command}"
        end

        run(command)
      end

      # Executes a copy of the encrypted_data_bag_secret to the nodes
      # 
      # @param [String] encrypted_data_bag_secret_path
      #   the path to the encrypted_data_bag_secret
      # 
      # @return [#run]
      def put_secret(encrypted_data_bag_secret_path)
        secret  = File.read(encrypted_data_bag_secret_path).chomp
        command = "echo '#{secret}' > /etc/chef/encrypted_data_bag_secret; chmod 0600 /etc/chef/encrypted_data_bag_secret"

        run(command)
      end
    end
  end
end
