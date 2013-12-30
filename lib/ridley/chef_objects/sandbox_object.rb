module Ridley
  class SandboxObject < ChefObject
    set_chef_id "sandbox_id"

    attribute :sandbox_id,
      type: String

    attribute :uri,
      type: String

    attribute :checksums,
      type: Hash

    attribute :is_completed,
      type: Buff::Boolean,
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
    #
    # @param [Hash] checksums
    #   a hash of file checksums and file paths
    #
    # @example
    #   sandbox.upload(
    #     "e5a0f6b48d0712382295ff30bec1f9cc" => "/Users/reset/code/rbenv-cookbook/recipes/default.rb",
    #     "de6532a7fbe717d52020dc9f3ae47dbe" => "/Users/reset/code/rbenv-cookbook/recipes/ohai_plugin.rb"
    #   )
    def upload(checksums)
      resource.upload(self, checksums)
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
