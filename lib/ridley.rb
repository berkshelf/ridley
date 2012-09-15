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

require 'ridley/version'
require 'ridley/errors'

# @author Jamie Winsor <jamie@vialstudios.com>
module Ridley
  CHEF_VERSION = '10.12.0'.freeze

  autoload :Log, 'ridley/log'  
  autoload :Connection, 'ridley/connection'
  autoload :DSL, 'ridley/dsl'
  autoload :Context, 'ridley/context'
  autoload :Resource, 'ridley/resource'
  autoload :Environment, 'ridley/resources/environment'
  autoload :Role, 'ridley/resources/role'
  autoload :Client, 'ridley/resources/client'
  autoload :Node, 'ridley/resources/node'
  autoload :DataBag, 'ridley/resources/data_bag'
  autoload :DataBagItem, 'ridley/resources/data_bag_item'
  autoload :Cookbook, 'ridley/resources/cookbook'
  autoload :Search, 'ridley/resources/search'

  class << self
    def connection(*args)
      Connection.new(*args)
    end

    def sync(*args, &block)
      Connection.sync(*args, &block)
    end

    # @return [Ridley::Log]
    def log
      Ridley::Log
    end
    alias_method :logger, :log
  end
end

require 'ridley/middleware'
