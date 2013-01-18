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
      type: Array,
      default: Array.new

    attribute :files,
      type: Array,
      default: Array.new

    attribute :libraries,
      type: Array,
      default: Array.new

    attribute :metadata,
      type: Hashie::Mash

    attribute :providers,
      type: Array,
      default: Array.new

    attribute :recipes,
      type: Array,
      default: Array.new

    attribute :resources,
      type: Array,
      default: Array.new

    attribute :root_files,
      type: Array,
      default: Array.new

    attribute :templates,
      type: Array,
      default: Array.new

    attribute :version,
      type: String

    # Download a single file from a cookbook
    #
    # @param [#to_sym] filetype
    #   the type of file to download. These are broken up into the following types in Chef:
    #     - attribute (unsupported until resolved https://github.com/reset/chozo/issues/17)
    #     - definition
    #     - file
    #     - library
    #     - provider
    #     - recipe
    #     - resource
    #     - root_file
    #     - template
    #   these types are where the files are stored in your cookbook's structure. For example, a
    #   recipe would be stored in the recipes directory while a root_file is stored at the root
    #   of your cookbook
    # @param [String] name
    #   name of the file to download
    # @param [String] destination
    #   where to download the file to
    #
    # @return [nil]
    def download_file(filetype, name, destination)
      download_fun(filetype).call(name, destination)
    end

    private

      # Return a lambda for downloading a file from the cookbook of the given type
      # 
      # @param [#to_sym] filetype
      #
      # @return [lambda]
      #   a lambda which takes to parameters: target and path. Target is the URL to download from
      #   and path is the location on disk to steam the contents of the remote URL to.
      def download_fun(filetype)
        collection = case filetype.to_sym
        when :attribute
          raise Errors::InternalError, "downloading attribute files is not yet supported: https://github.com/reset/chozo/issues/17"
        when :definition; method(:definitions)
        when :file; method(:files)
        when :library; method(:libraries)
        when :provider; method(:providers)
        when :recipe; method(:recipes)
        when :resource; method(:resources)
        when :root_file; method(:root_files)
        when :template; method(:templates)
        else
          raise Errors::UnknownCookbookFileType.new(filetype)
        end

        ->(target, destination) {
          file = collection.call.find { |f| f.name == target }
          return nil if file.nil?
          client.connection.get(file[:url])
        }
      end
  end
end
