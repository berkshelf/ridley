module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class SandboxResource
    class << self
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
      def create(client, checksums = [])
        sumhash = { checksums: Hash.new }.tap do |chks|
          Array(checksums).each { |chk| chks[:checksums][chk] = nil }
        end

        new(client, client.connection.post("sandboxes", MultiJson.encode(sumhash)).body)
      end
    end

    include Chozo::VariaModel

    attribute :sandbox_id,
      type: String

    attribute :uri,
      type: String

    attribute :checksums,
      type: Hash

    attribute :is_completed,
      type: Boolean,
      default: false

    attr_reader :client

    # @param [Ridley::Client] client
    # @param [Hash] new_attrs
    def initialize(client, new_attrs = {})
      @client = client
      mass_assign(new_attrs)
    end

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
    def commit
      response = client.connection.put("sandboxes/#{sandbox_id}", MultiJson.encode(is_completed: true)).body
      set_attribute(:is_completed, response[:is_completed])
    end

    def to_s
      "#{sandbox_id}: #{checksums}"
    end
  end
end
