require 'chozo'
require 'celluloid'
require 'faraday'
require 'addressable/uri'
require 'multi_json'
require 'solve'
require 'active_support/inflector'
require 'forwardable'
require 'thread'
require 'pathname'

if jruby?
  require 'json/pure'
else
  require 'json/ext'
end

require 'ridley/version'
require 'ridley/errors'

JSON.create_id = nil

# @author Jamie Winsor <reset@riotgames.com>
module Ridley
  CHEF_VERSION = '11.4.0'.freeze

  autoload :Bootstrapper, 'ridley/bootstrapper'
  autoload :Client, 'ridley/client'
  autoload :Connection, 'ridley/connection'
  autoload :ChainLink, 'ridley/chain_link'
  autoload :Chef, 'ridley/chef'
  autoload :DSL, 'ridley/dsl'
  autoload :Logging, 'ridley/logging'
  autoload :Mixin, 'ridley/mixin'
  autoload :Resource, 'ridley/resource'
  autoload :SandboxUploader, 'ridley/sandbox_uploader'
  autoload :SSH, 'ridley/ssh'

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

require 'ridley/middleware'
require 'ridley/resources'
