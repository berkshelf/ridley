module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Bootstrapper
    autoload :Context, 'ridley/bootstrapper/context'

    class << self
      # @return [Pathname]
      def templates_path
        Ridley.root.join('bootstrappers')
      end

      # @return [String]
      def default_template
        templates_path.join('omnibus.erb').to_s
      end
    end

    include Celluloid
    include Celluloid::Logger

    # @return [Array<String>]
    attr_reader :hosts

    # @return [Array<Bootstrapper::Context>]
    attr_reader :contexts

    # @return [Hash]
    attr_reader :ssh_config

    # @param [Ridley::Connection] connection
    # @param [Array<#to_s>] hosts
    # @option options [Hash] :timeout
    #   timeout value for SSH bootstrap (default: 1.5)
    # @option options [String] :validator_path
    #   filepath to the validator used to bootstrap the node (required)
    # @option options [String] :bootstrap_proxy
    #   URL to a proxy server to bootstrap through (default: nil)
    # @option options [String] :encrypted_data_bag_secret_path
    #   filepath on your host machine to your organizations encrypted data bag secret (default: nil)
    # @option options [Hash] :hints
    #   a hash of Ohai hints to place on the bootstrapped node (default: Hash.new)
    # @option options [Hash] :attributes
    #   a hash of attributes to use in the first Chef run (default: Hash.new)
    # @option options [Array] :run_list
    #   an initial run list to bootstrap with (default: Array.new)
    # @option options [String] :chef_version
    #   version of Chef to install on the node (default: {Ridley::CHEF_VERSION})
    # @option options [String] :environment
    #   environment to join the node to (default: '_default')
    # @option options [Boolean] :sudo
    #   bootstrap with sudo (default: true)
    # @option options [String] :template
    #   bootstrap template to use (default: omnibus)
    def initialize(connection, hosts, options = {})
      @connection = connection
      @hosts      = Array(hosts).collect(&:to_s)
      @ssh_config = connection.ssh

      @contexts = @hosts.collect do |host|
        Context.new(connection, host, options)
      end

      self.ssh_config[:timeout] = options.fetch(:timeout, 1.5)
    end

    # @param [String] command
    #
    # @return [Array]
    def run
      workers = Array.new
      workers = contexts.collect do |context|
        worker = SSH::Worker.new_link(current_actor, context.host, self.ssh_config)
        worker.async.run(context.boot_command)
        worker
      end

      [].tap do |responses|
        until responses.length == workers.length
          receive { |msg|
            status, response = msg
            
            case status
            when :ok, :error
              responses << msg
            else
              error "No match for status: '#{status}'. terminating..."
              terminate
            end
          }
        end
      end
    ensure
      workers.collect(&:terminate)
    end

    private

      attr_reader :connection
  end
end
