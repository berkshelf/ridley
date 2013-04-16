module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class SandboxResource < Ridley::Resource
    set_resource_path "sandboxes"
    represented_by Ridley::SandboxObject

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
  end
end
