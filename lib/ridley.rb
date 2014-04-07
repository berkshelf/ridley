require 'addressable/uri'
require 'celluloid'
require 'celluloid/io'
require 'faraday'
require 'forwardable'
require 'hashie'
require 'json'
require 'pathname'
require 'semverse'

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

    # Create a new Ridley connection from the Chef config (knife.rb)
    #
    # @param [#to_s] filepath
    #   the path to the Chef Config
    #
    # @param [hash] options
    #   list of options to pass to the Ridley connection (@see {Ridley::Client#new})
    #
    # @return [Ridley::Client]
    def from_chef_config(filepath = nil, options = {})
      config = Ridley::Chef::Config.new(filepath).to_hash

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
  end

  require_relative 'ridley/mixin'
  require_relative 'ridley/logging'
  require_relative 'ridley/logger'
  require_relative 'ridley/chef_object'
  require_relative 'ridley/chef_objects'
  require_relative 'ridley/client'
  require_relative 'ridley/connection'
  require_relative 'ridley/chef'
  require_relative 'ridley/middleware'
  require_relative 'ridley/resource'
  require_relative 'ridley/resources'
  require_relative 'ridley/sandbox_uploader'
  require_relative 'ridley/version'
  require_relative 'ridley/errors'
end

Celluloid.logger = Ridley.logger
