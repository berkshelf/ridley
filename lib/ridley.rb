require 'faraday'
require 'addressable/uri'
require 'multi_json'
require 'active_model'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'forwardable'
require 'set'

require 'ridley/errors'

module Ridley
  CHEF_VERSION = '10.12.0'.freeze

  autoload :Log, 'ridley/log'  
  autoload :Connection, 'ridley/connection'
  autoload :Resource, 'ridley/resource'
  autoload :Environment, 'ridley/resources/environment'
  autoload :Role, 'ridley/resources/role'
  autoload :Client, 'ridley/resources/client'
  autoload :Node, 'ridley/resources/node'
  autoload :DataBag, 'ridley/resources/data_bag'
  autoload :Cookbook, 'ridley/resources/cookbook'
  autoload :DSL, 'ridley/dsl'

  class << self
    def connection(*args)
      Connection.new(*args)
    end

    def start(*args, &block)
      connection(*args).start(&block)
    end

    def log
      Ridley::Log
    end
    alias_method :logger, :log
  end
end

require 'ridley/middleware'
