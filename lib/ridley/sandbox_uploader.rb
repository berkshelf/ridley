module Ridley
  # @api private
  class SandboxUploader
    class << self
      # Return the checksum of the contents of the file at the given filepath
      #
      # @param [String] io
      #   a filepath or an IO
      # @param [Digest::Base] digest
      #
      # @return [String]
      #   the binary checksum of the contents of the file
      def checksum(io, digest = Digest::MD5.new)
        while chunk = io.read(1024 * 8)
          digest.update(chunk)
        end
        digest.hexdigest
      end

      # Return a base64 encoded checksum of the contents of the given file. This is the expected
      # format of sandbox checksums given to the Chef Server.
      #
      # @param [String] io
      #   a filepath or an IO
      #
      # @return [String]
      #   a base64 encoded checksum
      def checksum64(io)
        Base64.encode64([checksum(io)].pack("H*")).strip
      end
    end

    include Celluloid

    attr_reader :client_name
    attr_reader :client_key
    attr_reader :options

    def initialize(client_name, client_key, options = {})
      @client_name = client_name
      @client_key  = client_key
      @options     = options
    end

    # Upload one file into the sandbox for the given checksum id
    #
    # @param [Ridley::SandboxObject] sandbox
    # @param [String] chk_id
    #   checksum of the file being uploaded
    # @param [String, #read] file
    #   a filepath or an IO
    #
    # @raise [Errors::ChecksumMismatch]
    #   if the given file does not match the expected checksum
    #
    # @return [Hash, nil]
    def upload(sandbox, chk_id, file)
      checksum = sandbox.checksum(chk_id)

      unless checksum[:needs_upload]
        return nil
      end

      io                  = file.respond_to?(:read) ? file : File.new(file, 'rb')
      calculated_checksum = self.class.checksum64(io)
      expected_checksum   = Base64.encode64([chk_id].pack('H*')).strip

      unless calculated_checksum == expected_checksum
        raise Errors::ChecksumMismatch,
          "Error uploading #{chk_id}. Expected #{expected_checksum} but got #{calculated_checksum}"
      end

      headers = {
        'Content-Type' => 'application/x-binary',
        'content-md5' => calculated_checksum
      }

      url         = URI(checksum[:url])
      upload_path = url.path
      url.path    = ""

      # versions prior to OSS Chef 11 will strip the port to upload the file to in the checksum
      # url returned. This will ensure we are uploading to the proper location.
      if sandbox.send(:resource).connection.foss?
        url.port = URI(sandbox.send(:resource).connection.server_url).port
      end

      begin
        io.rewind

        Faraday.new(url, self.options) do |c|
          c.response :chef_response
          c.response :follow_redirects
          c.request :chef_auth, self.client_name, self.client_key
          c.adapter :net_http
        end.put(upload_path, io.read, headers)
      rescue Ridley::Errors::HTTPError => ex
        abort(ex)
      end
    end
  end
end
