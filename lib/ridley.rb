require 'celluloid'
require 'faraday'
require 'addressable/uri'
require 'yajl'
require 'multi_json'
require 'active_model'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'forwardable'
require 'set'
require 'thread'
require 'chozo/core_ext'

require 'ridley/version'
require 'ridley/errors'

# @author Jamie Winsor <jamie@vialstudios.com>
module Ridley
  CHEF_VERSION = '10.14.4'.freeze

  autoload :Client, 'ridley/resources/client'
  autoload :Connection, 'ridley/connection'
  autoload :Context, 'ridley/context'
  autoload :Cookbook, 'ridley/resources/cookbook'
  autoload :DataBag, 'ridley/resources/data_bag'
  autoload :DataBagItem, 'ridley/resources/data_bag_item'
  autoload :DSL, 'ridley/dsl'
  autoload :Environment, 'ridley/resources/environment'
  autoload :Logging, 'ridley/logging'
  autoload :Node, 'ridley/resources/node'
  autoload :Resource, 'ridley/resource'
  autoload :Role, 'ridley/resources/role'
  autoload :Search, 'ridley/resources/search'
  autoload :SSH, 'ridley/ssh'

  class << self
    attr_accessor :logger

    def connection(*args)
      Connection.new(*args)
    end

    def sync(*args, &block)
      Connection.sync(*args, &block)
    end

    # @return [Logger]
    def logger
      Ridley::Logging.logger
    end
    alias_method :log, :logger

    # @param [Logger, nil] obj
    #
    # @return [Logger]
    def set_logger(obj)
      Ridley::Logging.set_logger(obj)
    end
  end
end

Celluloid.logger = Ridley.logger

require 'ridley/middleware'
