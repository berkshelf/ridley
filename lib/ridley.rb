require 'active_support/core_ext/kernel/reporting'
# Silencing warnings because not all versions of GSSAPI support all of the GSSAPI methods
# the gssapi gem attempts to attach to and these warnings are dumped to STDERR.
silence_warnings do
  # Requiring winrm before all other gems because of https://github.com/WinRb/WinRM/issues/39
  require 'winrm'
end

require 'active_support/inflector'
require 'addressable/uri'
require 'celluloid'
require 'chozo'
require 'faraday'
require 'forwardable'
require 'multi_json'
require 'pathname'
require 'solve'
require 'thread'

if jruby?
  require 'json/pure'
else
  require 'json/ext'
end

JSON.create_id = nil

# @author Jamie Winsor <reset@riotgames.com>
module Ridley
  require_relative 'ridley/bootstrap_bindings'
  require_relative 'ridley/bootstrapper'
  require_relative 'ridley/chef_object'
  require_relative 'ridley/chef_objects'
  require_relative 'ridley/client'
  require_relative 'ridley/connection'
  require_relative 'ridley/chef'
  require_relative 'ridley/host_connector'
  require_relative 'ridley/logging'
  require_relative 'ridley/middleware'
  require_relative 'ridley/mixin'
  require_relative 'ridley/resource'
  require_relative 'ridley/resources'
  require_relative 'ridley/sandbox_uploader'
  require_relative 'ridley/version'
  require_relative 'ridley/errors'

  CHEF_VERSION = '11.4.0'.freeze

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
