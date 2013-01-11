require 'chozo'
require 'celluloid'
require 'faraday'
require 'addressable/uri'
require 'multi_json'
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

# @author Jamie Winsor <jamie@vialstudios.com>
module Ridley
  CHEF_VERSION = '10.16.4'.freeze

  autoload :Bootstrapper, 'ridley/bootstrapper'
  autoload :Connection, 'ridley/connection'
  autoload :ChainLink, 'ridley/chain_link'
  autoload :DSL, 'ridley/dsl'
  autoload :Logging, 'ridley/logging'
  autoload :Resource, 'ridley/resource'
  autoload :SSH, 'ridley/ssh'

  class << self
    extend Forwardable

    def_delegator "Ridley::Logging", :logger
    alias_method :log, :logger

    def_delegator "Ridley::Logging", :logger=
    def_delegator "Ridley::Logging", :set_logger

    def connection(*args)
      Connection.new(*args)
    end

    def sync(*args, &block)
      Connection.sync(*args, &block)
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
