module Ridley
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

      # Return the checksum of the contents of the file at the given filepath
      #
      # @param [String] path
      #   file to checksum
      #
      # @return [String]
      #   the binary checksum of the contents of the file
      def checksum(path)
        File.open(path, 'rb') { |f| checksum_io(f, Digest::MD5.new) }
      end

      # Checksum and encode the file at the given filepath for uploading
      #
      # @param [String] path
      #
      # @return [String]
      #   a base64 encoded checksum
      def checksum64(path)
        Base64.encode64([checksum(path)].pack("H*")).strip
      end

      # @param [String] io
      # @param [Object] digest
      #
      # @return [String]
      def checksum_io(io, digest)
        while chunk = io.read(1024 * 8)
          digest.update(chunk)
        end
        digest.hexdigest
      end
    end

    include Chozo::VariaModel

    attribute :uri,
      type: String

    attribute :checksums,
      type: Hash

    attribute :sandbox_id,
      type: String

    # @param [Ridley::Client] client
    # @param [Hash] new_attrs
    def initialize(client, new_attrs = {})
      @client = client
      mass_assign(new_attrs)
    end

    def checksum(chk_id)
      checksums.fetch(chk_id.to_sym)
    end

    # Concurrently upload multiple files into a sandbox
    #
    # @param [Hash] checksums
    #   a hash of file checksums and file paths
    #
    # @example uploading multiple checksums
    #
    #   sandbox.multi_upload(
    #     "e5a0f6b48d0712382295ff30bec1f9cc" => "/Users/reset/code/rbenv-cookbook/recipes/default.rb",
    #     "de6532a7fbe717d52020dc9f3ae47dbe" => "/Users/reset/code/rbenv-cookbook/recipes/ohai_plugin.rb"
    #   )
    def multi_upload(checksums)
      checksums.collect do |chk_id, path|
        future.upload(chk_id, path)
      end.map(&:value)
    end

    # Upload one file into the sandbox for the given checksum id
    #
    # @param [String] chk_id
    #   checksum of the file being uploaded
    # @param [String] path
    #   path to the file to upload
    #
    # @return [Hash, nil]
    def upload(chk_id, path)
      checksum = self.checksum(chk_id)
      
      unless checksum[:needs_upload]
        return nil
      end

      headers  = {
        'Content-Type' => 'application/x-binary',
        'content-md5' => self.class.checksum64(path)
      }
      contents = File.open(path, 'rb') { |f| f.read }

      # Hosted Chef returns Amazon S3 URLs for where to upload
      # checksums to. OSS Chef Server and Hosted Chef return URLs
      # to the same Chef API that the Sandbox creation request was
      # sent to.
      #
      # The client object is duplicated to ensure all of our client
      # settings persist, but the scheme, host, and port are set to the
      # value of the given checksum.
      conn = client.send(:conn).dup

      url         = URI(checksum[:url])
      upload_path = url.path
      url.path    = ""

      conn.url_prefix = url.to_s

      conn.put(upload_path, contents, headers)
    end

    def commit
      client.put("sandboxes/#{sandbox_id}", MultiJson.encode(is_completed: true)).body
    end

    def to_s
      "#{sandbox_id}: #{checksums}"
    end

    private

      attr_reader :client
  end
end
