module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class CookbookResource < Ridley::Resource
    class << self
      # List all of the cookbooks and their versions present on the remote
      #
      # @example return value
      #   {
      #     "ant" => [
      #       "0.10.1"
      #     ],
      #     "apache2" => [
      #       "1.4.0"
      #     ]
      #   } 
      #
      # @param [Ridley::Client] client
      #
      # @return [Hash]
      #   a hash containing keys which represent cookbook names and values which contain
      #   an array of strings representing the available versions
      def all(client)
        response = client.connection.get(self.resource_path).body
        
        {}.tap do |cookbooks|
          response.each do |name, details|
            cookbooks[name] = details["versions"].collect { |version| version["version"] }
          end
        end
      end

      def create(*args)
        raise NotImplementedError
      end

      # Delete a cookbook of the given name and version on the remote Chef server
      #
      # @param [Ridley::Client] client
      # @param [String] name
      # @param [String] version
      #
      # @option options [Boolean] purge (false)
      #
      # @return [Boolean]
      def delete(client, name, version, options = {})
        options = options.reverse_merge(purge: false)
        url = "#{self.resource_path}/#{name}/#{version}"
        url += "?purge=true" if options[:purge]

        client.connection.delete(url).body
        true
      rescue Errors::HTTPNotFound
        true
      end

      # Delete all of the versions of a given cookbook on the remote Chef server
      #
      # @param [Ridley::Client] client
      # @param [String] name
      #   name of the cookbook to delete
      #
      # @option options [Boolean] purge (false)
      def delete_all(client, name, options = {})
        versions(client, name).each do |version|
          delete(client, name, version, options)
        end
      end

      # Download the entire cookbook
      #
      # @param [Ridley::Client] client
      # @param [String] name
      # @param [String] version
      # @param [String] destination (Dir.mktmpdir)
      #   the place to download the cookbook too. If no value is provided the cookbook
      #   will be downloaded to a temporary location
      #
      # @return [String]
      #   the path to the directory the cookbook was downloaded to
      def download(client, name, version, destination = Dir.mktmpdir)
        cookbook = find(client, name, version)
        
        unless cookbook.nil?
          cookbook.download(destination)
        end
      end

      # @param [Ridley::Client] client
      # @param [String, #chef_id] object
      # @param [String] version
      #
      # @return [nil, CookbookResource]
      def find(client, object, version)
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
      def find!(client, object, version)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        new(client, client.connection.get("#{self.resource_path}/#{chef_id}/#{version}").body)
      end

      # Return the latest version of the given cookbook found on the remote Chef server
      #
      # @param [Ridley::Client] client
      # @param [String] name
      #
      # @return [String, nil]
      def latest_version(client, name)
        ver = versions(client, name).collect do |version|
          Solve::Version.new(version)
        end.sort.last

        ver.nil? ? nil : ver.to_s
      end

      # Return the version of the given cookbook which best stasifies the given constraint
      #
      # @param [Ridley::Client] client
      # @param [String] name
      #   name of the cookbook
      # @param [String, Solve::Constraint] constraint
      #   constraint to solve for
      #
      # @return [CookbookResource, nil]
      #   returns the cookbook resource for the best solution or nil if no solution exists
      def satisfy(client, name, constraint)
        version = Solve::Solver.satisfy_best(constraint, versions(client, name)).to_s
        find(client, name, version)
      rescue Solve::Errors::NoSolutionError
        nil
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

      # Return a list of versions for the given cookbook present on the remote Chef server
      #
      # @param [Ridley::Client] client
      # @param [String] name
      #
      # @example
      #   versions(client, "nginx") => [ "1.0.0", "1.2.0" ]
      #
      # @return [Array<String>]
      def versions(client, name)
        response = client.connection.get("#{self.resource_path}/#{name}").body

        response[name]["versions"].collect do |cb_ver|
          cb_ver["version"]
        end
      end
    end

    include Ridley::Logging

    FILE_TYPES = [
      :resources,
      :providers,
      :recipes,
      :definitions,
      :libraries,
      :attributes,
      :files,
      :templates,
      :root_files
    ].freeze

    set_chef_id "name"
    set_chef_type "cookbook"
    set_chef_json_class "Chef::Cookbook"
    set_resource_path "cookbooks"

    attribute :name,
      required: true

    attribute :attributes,
      type: Array,
      default: Array.new

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

    # Download the entire cookbook
    #
    # @param [String] destination (Dir.mktmpdir)
    #   the place to download the cookbook too. If no value is provided the cookbook
    #   will be downloaded to a temporary location
    #
    # @return [String]
    #   the path to the directory the cookbook was downloaded to
    def download(destination = Dir.mktmpdir)
      destination = File.expand_path(destination)
      log.debug { "downloading cookbook: '#{name}'" }

      FILE_TYPES.each do |filetype|
        next unless manifest.has_key?(filetype)

        manifest[filetype].each do |file|
          file_destination = File.join(destination, file[:path].gsub('/', File::SEPARATOR))
          FileUtils.mkdir_p(File.dirname(file_destination))
          download_file(filetype, file[:name], file_destination)
        end
      end

      destination
    end

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

    # A hash containing keys for all of the different cookbook filetypes with values
    # representing each file of that type this cookbook contains
    #
    # @example
    #   {
    #     root_files: [
    #       {
    #         :name => "afile.rb",
    #         :path => "files/ubuntu-9.10/afile.rb",
    #         :checksum => "2222",
    #         :specificity => "ubuntu-9.10"
    #       },
    #     ],
    #     templates: [ manifest_record1, ... ],
    #     ...
    #   }
    #
    # @return [Hash]
    def manifest
      {}.tap do |manifest|
        FILE_TYPES.each do |filetype|
          manifest[filetype] = get_attribute(filetype)
        end
      end
    end

    def to_s
      "#{name}: #{manifest}"
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
        when :attribute, :attributes; method(:attributes)
        when :definition, :definitions; method(:definitions)
        when :file, :files; method(:files)
        when :library, :libraries; method(:libraries)
        when :provider, :providers; method(:providers)
        when :recipe, :recipes; method(:recipes)
        when :resource, :resources; method(:resources)
        when :root_file, :root_files; method(:root_files)
        when :template, :templates; method(:templates)
        else
          raise Errors::UnknownCookbookFileType.new(filetype)
        end

        ->(target, destination) {
          files = collection.call # JW: always chaining .call.find results in a nil value. WHY?
          file  = files.find { |f| f[:name] == target }
          return nil if file.nil?

          destination = File.expand_path(destination)
          log.debug { "downloading '#{filetype}' file: #{file} to: '#{destination}'" }

          client.connection.stream(file[:url], destination)
        }
      end
  end
end
