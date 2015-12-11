require 'chef-config/config'
require 'chef-config/workstation_config_loader'
require 'socket'

module Ridley::Chef
  class Config
    # Create a new Chef Config object.
    #
    # @param [#to_s] path
    #   the path to the configuration file
    # @param [Hash] options
    def initialize(path, options = {})
      ChefConfig::WorkstationConfigLoader.new(path).load
      ChefConfig::Config.merge!(options)
      ChefConfig::Config.export_proxies # Set proxy settings as environment variables
    end

    # The configuration as a hash
    def to_hash
      ChefConfig::Config.save(true)
    end
  end
end
