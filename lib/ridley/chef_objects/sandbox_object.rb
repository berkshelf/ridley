module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class SandboxObject < ChefObject
    attribute :sandbox_id,
      type: String

    attribute :uri,
      type: String

    attribute :checksums,
      type: Hash

    attribute :is_completed,
      type: Boolean,
      default: false

    # Return information about the given checksum
    #
    # @example
    #   sandbox.checksum("e5a0f6b48d0712382295ff30bec1f9cc") => {
    #     needs_upload: true,
    #     url: "https://s3.amazonaws.com/opscode-platform-production-data/organization"
    #   }
    #
    # @param [#to_sym] chk_id
    #   checksum to retrieve information about
    #
    # @return [Hash]
    #   a hash containing the checksum information
    def checksum(chk_id)
      checksums[chk_id.to_sym]
    end

    # Concurrently upload all of this sandboxes files into the checksum containers of the sandbox
    def upload(checksums)
      SandboxUploader.upload(self, checksums)
    end

    # Notify the Chef Server that uploading to this sandbox has completed
    #
    # @raise [Ridley::Errors::SandboxCommitError]
    def commit
      response = resource.commit(self)
      set_attribute(:is_completed, response[:is_completed])
    end
  end
end
