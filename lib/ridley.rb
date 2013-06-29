require 'addressable/uri'
require 'celluloid'
require 'celluloid/io'
require 'faraday'
require 'forwardable'
require 'hashie'
require 'json'
require 'pathname'
require 'solve'

JSON.create_id = nil

module Ridley
  CHEF_VERSION = '11.4.0'.freeze

  class << self
    extend Forwardable

    def_delegator "Ridley::Logging", :logger
    alias_method :log, :logger

    def_delegator "Ridley::Logging", :logger=
    def_delegator "Ridley::Logging", :set_logger

    # @return [Ridley::Client]
    def new(*args)
      Client.new(*args)
    end

    # @return [Ridley::Client]
    def from_chef_config(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      config = Ridley::Chef::Config.new(args.first).to_hash

      config[:validator_client] = config.delete(:validation_client_name)
      config[:validator_path]   = config.delete(:validation_key)
      config[:client_name]      = config.delete(:node_name)
      config[:server_url]       = config.delete(:chef_server_url)

      Client.new(config.merge(options))
    end

    def open(*args, &block)
      Client.open(*args, &block)
    end

    # @return [Pathname]
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end

    # @return [Pathname]
    def scripts
      root.join('scripts')
    end
  end

  require_relative 'ridley/mixin'
  require_relative 'ridley/logging'
  require_relative 'ridley/bootstrap_context'
  require_relative 'ridley/command_context'
  require_relative 'ridley/chef_object'
  require_relative 'ridley/chef_objects'
  require_relative 'ridley/client'
  require_relative 'ridley/connection'
  require_relative 'ridley/chef'
  require_relative 'ridley/host_commander'
  require_relative 'ridley/host_connector'
  require_relative 'ridley/middleware'
  require_relative 'ridley/resource'
  require_relative 'ridley/resources'
  require_relative 'ridley/sandbox_uploader'
  require_relative 'ridley/version'
  require_relative 'ridley/errors'
end

Celluloid.logger = Ridley.logger
