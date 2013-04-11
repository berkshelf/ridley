module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class CookbookObject < Ridley::ChefObject
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

    attribute :frozen?,
      type: Boolean

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
          download_file(filetype, file[:path], file_destination)
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
    # @param [String] path
    #   path of the file to download
    # @param [String] destination
    #   where to download the file to
    #
    # @return [nil]
    def download_file(filetype, path, destination)
      download_fun(filetype).call(path, destination)
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
          file  = files.find { |f| f[:path] == target }
          return nil if file.nil?

          destination = File.expand_path(destination)
          log.debug { "downloading '#{filetype}' file: #{file} to: '#{destination}'" }

          connection.stream(file[:url], destination)
        }
      end
  end
end
