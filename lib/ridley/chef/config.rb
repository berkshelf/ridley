require 'buff/config/ruby'
require 'socket'

module Ridley::Chef
  class Config < Buff::Config::Ruby
    class << self
      # Return the most sensible path to the Chef configuration file. This can
      # be configured by setting a value for the 'RIDLEY_CHEF_CONFIG' environment
      # variable.
      #
      # @return [String, nil]
      def location
        possibles = []

        possibles << ENV['RIDLEY_CHEF_CONFIG'] if ENV['RIDLEY_CHEF_CONFIG']
        possibles << File.join(ENV['KNIFE_HOME'], 'knife.rb') if ENV['KNIFE_HOME']
        possibles << File.join(working_dir, 'knife.rb') if working_dir

        # Ascending search for .chef directory siblings
        Pathname.new(working_dir).ascend do |file|
          sibling_chef = File.join(file, '.chef')
          possibles << File.join(sibling_chef, 'knife.rb')
        end if working_dir

        possibles << File.join(ENV['HOME'], '.chef', 'knife.rb') if ENV['HOME']
        possibles.compact!

        location = possibles.find { |loc| File.exists?(File.expand_path(loc)) }

        File.expand_path(location) unless location.nil?
      end

      private

        # The current working directory
        #
        # @return [String]
        def working_dir
          ENV['PWD'] || Dir.pwd
        end
    end

    set_assignment_mode :carefree

    attribute :node_name,
      default: Socket.gethostname
    attribute :chef_server_url,
      default: 'http://localhost:4000'
    attribute :client_key,
      default: platform_specific_path('/etc/chef/client.pem')
    attribute :validation_key,
      default: platform_specific_path('/etc/chef/validation.pem')
    attribute :validation_client_name,
      default: 'chef-validator'

    attribute :cookbook_copyright,
      default: 'YOUR_NAME'
    attribute :cookbook_email,
      default: 'YOUR_EMAIL'
    attribute :cookbook_license,
      default: 'reserved'

    attribute :knife,
      default: {}

    # Prior to Chef 11, the cache implementation was based on
    # moneta and configured via cache_options[:path]. Knife configs
    # generated with Chef 11 will have `syntax_check_cache_path`, but older
    # configs will have `cache_options[:path]`. `cache_options` is marked
    # deprecated in chef/config.rb but doesn't currently trigger a warning.
    # See also: CHEF-3715
    attribute :syntax_check_cache_path,
      default: Dir.mktmpdir
    attribute :cache_options,
      default: { path: defined?(syntax_check_cache_path) ? syntax_check_cache_path : Dir.mktmpdir }

    # Create a new Chef Config object.
    #
    # @param [#to_s] path
    #   the path to the configuration file
    # @param [Hash] options
    def initialize(path, options = {})
      super(path || self.class.location, options)
    end
  end
end
