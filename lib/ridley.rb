require 'active_support/inflector'
require 'addressable/uri'
require 'celluloid'
require 'chozo'
require 'faraday'
require 'forwardable'
require 'hashie'
require 'json'
require 'pathname'
require 'solve'

JSON.create_id = nil

# @author Jamie Winsor <reset@riotgames.com>
module Ridley
  CHEF_VERSION = '11.4.0'.freeze

  require_relative 'ridley/mixin'
  require_relative 'ridley/bootstrap_bindings'
  require_relative 'ridley/bootstrapper'
  require_relative 'ridley/chef_object'
  require_relative 'ridley/chef_objects'
  require_relative 'ridley/client'
  require_relative 'ridley/connection'
  require_relative 'ridley/chef'
  require_relative 'ridley/host_commander'
  require_relative 'ridley/host_connector'
  require_relative 'ridley/logging'
  require_relative 'ridley/middleware'
  require_relative 'ridley/resource'
  require_relative 'ridley/resources'
  require_relative 'ridley/sandbox_uploader'
  require_relative 'ridley/version'
  require_relative 'ridley/errors'

  class << self
    extend Forwardable

    def_delegator "Ridley::Logging", :logger
    alias_method :log, :logger

    def_delegator "Ridley::Logging", :logger=
    def_delegator "Ridley::Logging", :set_logger

    def new(*args)
      Client.new(*args)
    end

    def open(*args, &block)
      Client.open(*args, &block)
    end

    # @return [Pathname]
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end
  end
end

Celluloid.logger = Ridley.logger
