module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class SandboxResource < Ridley::Resource
    set_resource_path "sandboxes"
    represented_by Ridley::SandboxObject

    finalizer do
      uploader.terminate if uploader && uploader.alive?
    end

    def initialize(connection_registry, client_name, client_key, options = {})
      super(connection_registry)
      options   = options.reverse_merge(pool_size: 4)
      @uploader = SandboxUploader.pool(size: options[:pool_size], args: [ client_name, client_key, options ])
    end

    # Create a new Sandbox on the client's Chef Server. A Sandbox requires an
    # array of file checksums which lets the Chef Server know what the signature
    # of the contents to be uploaded will look like.
    #
    # @param [Ridley::Client] client
    # @param [Array] checksums
    #   a hash of file checksums
    #
    # @example using the Ridley client to create a sandbox
    #   client.sandbox.create([
    #     "385ea5490c86570c7de71070bce9384a",
    #     "f6f73175e979bd90af6184ec277f760c",
    #     "2e03dd7e5b2e6c8eab1cf41ac61396d5"
    #   ])
    #
    # @return [Array<Ridley::SandboxResource>]
    def create(checksums = [])
      sumhash = { checksums: Hash.new }.tap do |chks|
        Array(checksums).each { |chk| chks[:checksums][chk] = nil }
      end
      new(connection.post(self.class.resource_path, MultiJson.encode(sumhash)).body)
    end

    # @param [#chef_id] object
    #
    # @raise [Ridley::Errors::SandboxCommitError]
    # @raise [Ridley::Errors::ResourceNotFound]
    # @raise [Ridley::Errors::PermissionDenied]
    #
    # @return [Hash]
    def commit(object)
      chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
      connection.put("#{self.class.resource_path}/#{chef_id}", MultiJson.encode(is_completed: true)).body
    rescue Ridley::Errors::HTTPBadRequest => ex
      abort Ridley::Errors::SandboxCommitError.new(ex.message)
    rescue Ridley::Errors::HTTPNotFound => ex
      abort Ridley::Errors::ResourceNotFound.new(ex.message)
    rescue Ridley::Errors::HTTPUnauthorized, Ridley::Errors::HTTPForbidden => ex
      abort Ridley::Errors::PermissionDenied.new(ex.message)
    end

    # Concurrently upload all of the files in the given sandbox
    #
    # @param [Ridley::SandboxObject] sandbox
    # @param [Hash] checksums
    #   a hash of file checksums and file paths
    #
    # @example
    #   SandboxUploader.upload(sandbox,
    #     "e5a0f6b48d0712382295ff30bec1f9cc" => "/Users/reset/code/rbenv-cookbook/recipes/default.rb",
    #     "de6532a7fbe717d52020dc9f3ae47dbe" => "/Users/reset/code/rbenv-cookbook/recipes/ohai_plugin.rb"
    #   )
    #
    # @return [Array<Hash>]
    def upload(object, checksums)
      checksums.collect do |chk_id, path|
        uploader.future(:upload, object, chk_id, path)
      end.map(&:value)
    end

    def update(*args)
      raise RuntimeError, "action not supported"
    end

    def all(*args)
      raise RuntimeError, "action not supported"
    end

    def find(*args)
      raise RuntimeError, "action not supported"
    end

    def delete(*args)
      raise RuntimeError, "action not supported"
    end

    def delete_all(*args)
      raise RuntimeError, "action not supported"
    end

    private

      attr_reader :uploader
  end
end
