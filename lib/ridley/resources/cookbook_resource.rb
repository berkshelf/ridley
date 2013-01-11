module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class CookbookResource < Ridley::Resource
    class << self
      # Save a new Cookbook Version of the given name, version with the
      # given manifest of files and checksums.
      #
      # @param [Ridley::Connection] connection
      # @param [String] name
      # @param [String] version
      # @param [String] manifest
      #   a JSON blob containing file names, file paths, and checksums for each
      #   that describe the cookbook version being uploaded.
      #
      # @option options [Boolean] :freeze
      # @option options [Boolean] :force
      #
      # @return [Hash]
      def save(connection, name, version, manifest, options = {})
        freeze = options.fetch(:freeze, false)
        force  = options.fetch(:force, false)

        url = "cookbooks/#{name}/#{version}"
        url << "?force=true" if force

        connection.put(url, manifest)
      end
    end

    set_chef_id "name"
    set_chef_type "cookbook"
    set_chef_json_class "Chef::Cookbook"
    set_resource_path "cookbooks"

    attribute :name,
      required: true
  end

  module DSL
    # Coerces instance functions into class functions on Ridley::CookbookResource. This coercion
    # sends an instance of the including class along to the class function.
    #
    # @see Ridley::ChainLink
    #
    # @return [Ridley::ChainLink]
    #   a context object to delegate instance functions to class functions on Ridley::CookbookResource
    def cookbook
      ChainLink.new(self, Ridley::CookbookResource)
    end
  end
end
