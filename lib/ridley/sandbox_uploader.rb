module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  # @api private
  class SandboxUploader
    class << self
      # Concurrently upload all of the files in the given sandbox and then clean up
      # after ourselves
      #
      # @param [Ridley::SandboxResource] sandbox
      # @param [Hash] checksums
      #
      # @option options [Integer] :pool_size (12)
      #   the amount of concurrent uploads to perform
      def upload(sandbox, checksums, options = {})
        options = options.reverse_merge(
          pool_size: 12
        )
        uploader = pool(size: options[:pool_size], args: [sandbox])
        uploader.multi_upload(checksums)
      ensure
        uploader.terminate if uploader && uploader.alive?
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

      # Return a base64 encoded checksum of the contents of the given file. This is the expected
      # format of sandbox checksums given to the Chef Server.
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

    extend Forwardable
    include Celluloid

    attr_reader :sandbox

    def_delegator :sandbox, :client
    def_delegator :sandbox, :checksum

    def initialize(sandbox)
      @sandbox = sandbox
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

      url         = URI(checksum[:url])
      upload_path = url.path
      url.path    = ""

      # versions prior to OSS Chef 11 will strip the port to upload the file to in the checksum
      # url returned. This will ensure we are uploading to the proper location.
      if client.connection.foss?
        url.port = URI(client.connection.server_url).port
      end

      begin
        Faraday.new(url, client.options.slice(*Connection::VALID_OPTIONS)) do |c|
          c.response :chef_response
          c.response :follow_redirects
          c.request :chef_auth, client.client_name, client.client_key
          c.adapter :net_http
        end.put(upload_path, contents, headers)
      rescue Ridley::Errors::HTTPError => ex
        abort(ex)
      end
    end
  end
end
