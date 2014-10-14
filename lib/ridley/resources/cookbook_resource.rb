module Ridley
  class CookbookResource < Ridley::Resource
    task_class TaskThread

    set_resource_path "cookbooks"
    represented_by Ridley::CookbookObject

    def initialize(connection_registry, client_name, client_key, options = {})
      super(connection_registry)
      @sandbox_resource = SandboxResource.new_link(connection_registry, client_name, client_key, options)
    end

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
    # @return [Hash]
    #   a hash containing keys which represent cookbook names and values which contain
    #   an array of strings representing the available versions
    def all
      response = request(:get, self.class.resource_path, num_versions: "all")

      {}.tap do |cookbooks|
        response.each do |name, details|
          cookbooks[name] = details["versions"].collect { |version| version["version"] }
        end
      end
    end

    # Delete a cookbook of the given name and version on the remote Chef server
    #
    # @param [String] name
    # @param [String] version
    #
    # @option options [Boolean] purge (false)
    #
    # @return [Boolean]
    def delete(name, version, options = {})
      options = options.reverse_merge(purge: false)
      url = "#{self.class.resource_path}/#{name}/#{version}"
      url += "?purge=true" if options[:purge]

      request(:delete, url)
      true
    rescue AbortError => ex
      return nil if ex.cause.is_a?(Errors::HTTPNotFound)
      abort(ex.cause)
    end

    # Delete all of the versions of a given cookbook on the remote Chef server
    #
    # @param [String] name
    #   name of the cookbook to delete
    #
    # @option options [Boolean] purge (false)
    def delete_all(name, options = {})
      versions(name).collect { |version| future(:delete, name, version, options) }.map(&:value)
    end

    # Download the entire cookbook
    #
    # @param [String] name
    # @param [String] version
    # @param [String] destination (Dir.mktmpdir)
    #   the place to download the cookbook too. If no value is provided the cookbook
    #   will be downloaded to a temporary location
    #
    # @raise [Errors::ResourceNotFound] if the target cookbook is not found
    #
    # @return [String]
    #   the path to the directory the cookbook was downloaded to
    def download(name, version, destination = Dir.mktmpdir)
      if cookbook = find(name, version)
        cookbook.download(destination)
      else
        abort Errors::ResourceNotFound.new("cookbook #{name} (#{version}) was not found")
      end
    end

    # @param [String, #chef_id] object
    # @param [String] version
    #
    # @return [nil, CookbookResource]
    def find(object, version)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      new(request(:get, "#{self.class.resource_path}/#{chef_id}/#{version}"))
    rescue AbortError => ex
      return nil if ex.cause.is_a?(Errors::HTTPNotFound)
      abort(ex.cause)
    end

    # Return the latest version of the given cookbook found on the remote Chef server
    #
    # @param [String] name
    #
    # @raise [Errors::ResourceNotFound] if the target cookbook has no versions
    #
    # @return [String, nil]
    def latest_version(name)
      ver = versions(name).collect do |version|
        Semverse::Version.new(version)
      end.sort.last

      ver.nil? ? nil : ver.to_s
    end

    # Return the version of the given cookbook which best stasifies the given constraint
    #
    # @param [String] name
    #   name of the cookbook
    # @param [String, Semverse::Constraint] constraint
    #   constraint to solve for
    #
    # @raise [Errors::ResourceNotFound] if the target cookbook has no versions
    #
    # @return [CookbookResource, nil]
    #   returns the cookbook resource for the best solution or nil if no solution exists
    def satisfy(name, constraint)
      version = Semverse::Constraint.satisfy_best(constraint, versions(name)).to_s
      find(name, version)
    rescue Semverse::NoSolutionError
      nil
    end

    # Update or create a new Cookbook Version of the given name, version with the
    # given manifest of files and checksums.
    #
    # @param [Ridley::Chef::Cookbook] cookbook
    #   the cookbook to save
    #
    # @option options [Boolean] :force
    #   Upload the Cookbook even if the version already exists and is frozen on
    #   the target Chef Server
    # @option options [Boolean] :freeze
    #   Freeze the uploaded Cookbook on the Chef Server so that it cannot be
    #   overwritten
    #
    # @raise [Ridley::Errors::FrozenCookbook]
    #   if a cookbook of the same name and version already exists on the remote Chef server
    #   and is frozen. If the :force option is provided the given cookbook will be saved
    #   regardless.
    #
    # @return [Hash]
    def update(cookbook, options = {})
      options = options.reverse_merge(force: false, freeze: false)

      cookbook.frozen = options[:freeze]

      url = "cookbooks/#{cookbook.cookbook_name}/#{cookbook.version}"
      url << "?force=true" if options[:force]

      request(:put, url, cookbook.to_json)
    rescue AbortError => ex
      if ex.cause.is_a?(Errors::HTTPConflict)
        abort Ridley::Errors::FrozenCookbook.new(ex)
      end
      abort(ex.cause)
    end
    alias_method :create, :update

    # Uploads a cookbook to the remote Chef server from the contents of a filepath
    #
    # @param [String] path
    #   path to a cookbook on local disk
    #
    # @option options [Boolean] :force (false)
    #   Upload the Cookbook even if the version already exists and is frozen on
    #   the target Chef Server
    # @option options [Boolean] :freeze (false)
    #   Freeze the uploaded Cookbook on the Chef Server so that it cannot be
    #   overwritten
    # @option options [Boolean] :validate (true)
    #   Validate the contents of the cookbook before uploading
    #
    # @return [Hash]
    def upload(path, options = {})
      options  = options.reverse_merge(validate: true, force: false, freeze: false)
      cookbook = Ridley::Chef::Cookbook.from_path(path)

      unless (existing = find(cookbook.cookbook_name, cookbook.version)).nil?
        if existing.frozen? && options[:force] == false
          msg = "The cookbook #{cookbook.cookbook_name} (#{cookbook.version}) already exists and is"
          msg << " frozen on the Chef server. Use the 'force' option to override."
          abort Ridley::Errors::FrozenCookbook.new(msg)
        end
      end

      if options[:validate]
        cookbook.validate
      end

      # Compile metadata on upload if it hasn't been compiled already
      unless cookbook.compiled_metadata?
        compiled_metadata = cookbook.compile_metadata
        cookbook.reload
      end

      # Skip uploading the raw metadata (metadata.rb). The raw metadata is unecessary for the
      # client, and this is required until compiled metadata (metadata.json) takes precedence over
      # raw metadata in the Chef-Client.
      #
      # We can change back to including the raw metadata in the future after this has been fixed or
      # just remove these comments. There is no circumstance that I can currently think of where
      # raw metadata should ever be read by the client.
      #
      # - Jamie
      #
      # See the following tickets for more information:
      #   * https://tickets.opscode.com/browse/CHEF-4811
      #   * https://tickets.opscode.com/browse/CHEF-4810
      cookbook.manifest[:root_files].reject! do |file|
        File.basename(file[:name]).downcase == Ridley::Chef::Cookbook::Metadata::RAW_FILE_NAME
      end

      checksums = cookbook.checksums.dup
      sandbox   = sandbox_resource.create(checksums.keys.sort)

      sandbox.upload(checksums)
      sandbox.commit
      update(cookbook, options.slice(:force, :freeze))
    ensure
      # Destroy the compiled metadata only if it was created
      File.delete(compiled_metadata) unless compiled_metadata.nil?
    end

    # Return a list of versions for the given cookbook present on the remote Chef server
    #
    # @param [String] name
    #
    # @example
    #   versions("nginx") => [ "1.0.0", "1.2.0" ]
    #
    # @raise [Errors::ResourceNotFound] if the target cookbook has no versions
    #
    # @return [Array<String>]
    def versions(name)
      response = request(:get, "#{self.class.resource_path}/#{name}")

      response[name]["versions"].collect do |cb_ver|
        cb_ver["version"]
      end
    rescue AbortError => ex
      if ex.cause.is_a?(Errors::HTTPNotFound)
        abort Errors::ResourceNotFound.new(ex)
      end
      abort(ex.cause)
    end

    private

      attr_reader :sandbox_resource
  end
end
