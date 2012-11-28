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

    # @param [Array<#to_s>] hosts
    # @option options [String] :ssh_user
    # @option options [String] :ssh_password
    # @option options [Array<String>, String] :ssh_keys
    # @option options [Float] :ssh_timeout
    #   timeout value for SSH bootstrap (default: 1.5)
    # @option options [String] :validator_client
    # @option options [String] :validator_path
    #   filepath to the validator used to bootstrap the node (required)
    # @option options [String] :bootstrap_proxy (nil)
    #   URL to a proxy server to bootstrap through
    # @option options [String] :encrypted_data_bag_secret_path (nil)
    #   filepath on your host machine to your organizations encrypted data bag secret
    # @option options [Hash] :hints (Hash.new)
    #   a hash of Ohai hints to place on the bootstrapped node
    # @option options [Hash] :attributes (Hash.new)
    #   a hash of attributes to use in the first Chef run
    # @option options [Array] :run_list (Array.new)
    #   an initial run list to bootstrap with
    # @option options [String] :chef_version (Ridley::CHEF_VERSION)
    #   version of Chef to install on the node
    # @option options [String] :environment ('_default')
    #   environment to join the node to
    # @option options [Boolean] :sudo (true)
    #   bootstrap with sudo (default: true)
    # @option options [String] :template ('omnibus')
    #   bootstrap template to use
    def initialize(hosts, options = {})
      @hosts      = Array(hosts).collect(&:to_s).uniq
      @ssh_config = {
        user: options.fetch(:ssh_user),
        password: options[:ssh_password],
        keys: options[:ssh_keys],
        timeout: (options[:ssh_timeout] || 1.5),
        sudo: (options[:sudo].nil? ? true : options[:sudo])
      }

      @contexts = @hosts.collect do |host|
        Context.new(host, options)
      end
    end

    # @return [SSH::ResponseSet]
    def run
      if contexts.length >= 2
        pool = SSH::Worker.pool(size: contexts.length, args: [self.ssh_config])
      else
        pool = SSH::Worker.new(self.ssh_config)
      end

      responses = contexts.collect do |context|
        pool.future.run(context.host, context.boot_command)
      end.collect(&:value)

      SSH::ResponseSet.new.tap do |response_set|
        responses.each do |message|
          status, response = message

          case status
          when :ok
            response_set.add_ok(response)
          when :error
            response_set.add_error(response)
          end
        end
      end
    ensure
      pool.terminate if pool
    end
  end
end
