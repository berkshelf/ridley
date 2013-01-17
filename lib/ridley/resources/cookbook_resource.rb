module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class CookbookResource < Ridley::Resource
    class << self
      def create(*args)
        raise NotImplementedError
      end

      def delete(*args)
        raise NotImplementedError
      end

      def delete_all(*args)
        raise NotImplementedError
      end

      # @param [Ridley::Client] client
      # @param [String, #chef_id] object
      # @param [String] version
      #
      # @return [nil, CookbookResource]
      def find(client, object, version = nil)
        find!(client, object, version)
      rescue Errors::HTTPNotFound
        nil
      end

      # @param [Ridley::Client] client
      # @param [String, #chef_id] object
      # @param [String] version
      #
      # @raise [Errors::HTTPNotFound]
      #   if a resource with the given chef_id is not found
      #
      # @return [CookbookResource]
      def find!(client, object, version = nil)
        chef_id   = object.respond_to?(:chef_id) ? object.chef_id : object
        fetch_uri = "#{self.resource_path}/#{chef_id}"
        
        unless version.nil?
          fetch_uri = File.join(fetch_uri, version)
        end

        new(client, client.connection.get(fetch_uri).body)
      end

      # Save a new Cookbook Version of the given name, version with the
      # given manifest of files and checksums.
      #
      # @param [Ridley::Client] client
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
      def save(client, name, version, manifest, options = {})
        freeze = options.fetch(:freeze, false)
        force  = options.fetch(:force, false)

        url = "cookbooks/#{name}/#{version}"
        url << "?force=true" if force

        client.connection.put(url, manifest)
      end

      def update(*args)
        raise NotImplementedError
      end
    end

    set_chef_id "name"
    set_chef_type "cookbook"
    set_chef_json_class "Chef::Cookbook"
    set_resource_path "cookbooks"

    attribute :name,
      required: true

    # Broken until resolved: https://github.com/reset/chozo/issues/17
    # attribute :attributes,
    #   type: Array

    attribute :cookbook_name,
      type: String

    attribute :definitions,
      type: Array

    attribute :files,
      type: Array

    attribute :libraries,
      type: Array

    attribute :metadata,
      type: Hashie::Mash

    attribute :providers,
      type: Array

    attribute :recipes,
      type: Array

    attribute :resources,
      type: Array

    attribute :root_files,
      type: Array

    attribute :templates,
      type: Array

    attribute :version,
      type: String
  end
end
