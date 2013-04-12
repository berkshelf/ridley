module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class CookbookResource < Ridley::Resource
    set_chef_type "cookbook"
    set_chef_json_class "Chef::Cookbook"
    set_resource_path "cookbooks"
    represented_by Ridley::CookbookObject

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
      response = connection.get(self.resource_path).body

      {}.tap do |cookbooks|
        response.each do |name, details|
          cookbooks[name] = details["versions"].collect { |version| version["version"] }
        end
      end
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
    def delete(name, version, options = {})
      options = options.reverse_merge(purge: false)
      url = "#{self.class.resource_path}/#{name}/#{version}"
      url += "?purge=true" if options[:purge]

      connection.delete(url).body
      true
    rescue Errors::HTTPNotFound
      true
    end

    # Delete all of the versions of a given cookbook on the remote Chef server
    #
    # @param [String] name
    #   name of the cookbook to delete
    #
    # @option options [Boolean] purge (false)
    def delete_all(name, options = {})
      versions(client, name).each do |version|
        future(:delete, name, version, options)
      end.map(&:value)
    end

    # Download the entire cookbook
    #
    # @param [String] name
    # @param [String] version
    # @param [String] destination (Dir.mktmpdir)
    #   the place to download the cookbook too. If no value is provided the cookbook
    #   will be downloaded to a temporary location
    #
    # @return [String]
    #   the path to the directory the cookbook was downloaded to
    def download(name, version, destination = Dir.mktmpdir)
      cookbook = find(name, version)

      unless cookbook.nil?
        cookbook.download(destination)
      end
    end

    # @param [String, #chef_id] object
    # @param [String] version
    #
    # @return [nil, CookbookResource]
    def find(object, version)
      find!(object, version)
    rescue Errors::HTTPNotFound
      nil
    end

    # @param [String, #chef_id] object
    # @param [String] version
    #
    # @raise [Errors::HTTPNotFound]
    #   if a resource with the given chef_id is not found
    #
    # @return [CookbookResource]
    def find!(object, version)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      new(client.connection.get("#{self.resource_path}/#{chef_id}/#{version}").body)
    end

    # Return the latest version of the given cookbook found on the remote Chef server
    #
    # @param [String] name
    #
    # @return [String, nil]
    def latest_version(name)
      ver = versions(name).collect do |version|
        Solve::Version.new(version)
      end.sort.last

      ver.nil? ? nil : ver.to_s
    end

    # Return the version of the given cookbook which best stasifies the given constraint
    #
    # @param [String] name
    #   name of the cookbook
    # @param [String, Solve::Constraint] constraint
    #   constraint to solve for
    #
    # @return [CookbookResource, nil]
    #   returns the cookbook resource for the best solution or nil if no solution exists
    def satisfy(name, constraint)
      version = Solve::Solver.satisfy_best(constraint, versions(name)).to_s
      find(name, version)
    rescue Solve::Errors::NoSolutionError
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
      options.reverse_merge(force: false, freeze: false)

      cookbook.frozen = options[:freeze]

      url = "cookbooks/#{cookbook.cookbook_name}/#{cookbook.version}"
      url << "?force=true" if options[:force]

      connection.put(url, cookbook.to_json)
    rescue Ridley::Errors::HTTPConflict => ex
      raise Ridley::Errors::FrozenCookbook, ex
    end
    alias_method :create, :update

    # Uploads a cookbook to the remote Chef server from the contents of a filepath
    #
    # @param [String] path
    #   path to a cookbook on local disk
    #
    # @option options [String] :name
    #   automatically populated by the metadata of the cookbook at the given path, but
    #   in the event that the metadata does not contain a name it can be specified with
    #   this option
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
      options   = options.reverse_merge(validate: true, force: false, freeze: false)
      cookbook  = Ridley::Chef::Cookbook.from_path(path, options.slice(:name))

      unless (existing = find(cookbook.cookbook_name, cookbook.version)).nil?
        if existing.frozen? && options[:force] == false
          msg = "The cookbook #{cookbook.cookbook_name} (#{cookbook.version}) already exists and is"
          msg << " frozen on the Chef server. Use the 'force' option to override."
          raise Ridley::Errors::FrozenCookbook, msg
        end
      end

      if options[:validate]
        cookbook.validate
      end

      checksums = cookbook.checksums.dup
      sandbox   = sandbox.create(checksums.keys)

      sandbox.upload(checksums)
      sandbox.commit
      update(cookbook, options.slice(:force, :freeze))
    end

    # Return a list of versions for the given cookbook present on the remote Chef server
    #
    # @param [String] name
    #
    # @example
    #   versions(client, "nginx") => [ "1.0.0", "1.2.0" ]
    #
    # @return [Array<String>]
    def versions(name)
      response = connection.get("#{self.class.resource_path}/#{name}").body

      response[name]["versions"].collect do |cb_ver|
        cb_ver["version"]
      end
    end
  end
end
