require 'open-uri'

module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Connection < Faraday::Connection
    include Celluloid

    VALID_OPTIONS = [
      :params,
      :headers,
      :request,
      :ssl,
      :proxy
    ]

    attr_reader :organization
    attr_reader :client_key
    attr_reader :client_name

    # @param [String] server_url
    # @param [String] client_name
    # @param [String] client_key
    #
    # @option options [Hash] :params
    #   URI query unencoded key/value pairs
    # @option options [Hash] :headers
    #   unencoded HTTP header key/value pairs
    # @option options [Hash] :request
    #   request options
    # @option options [Hash] :ssl
    #   * :verify (Boolean) [true] set to false to disable SSL verification
    # @option options [URI, String, Hash] :proxy
    #   URI, String, or Hash of HTTP proxy options
    def initialize(server_url, client_name, client_key, options = {})
      @client_name  = client_name
      @client_key   = client_key

      options = options.reverse_merge(
        builder: Faraday::Builder.new { |b|
          b.request :chef_auth, client_name, client_key
          b.response :chef_response
          b.response :json

          b.adapter :net_http_persistent
        }
      )

      uri_hash = Addressable::URI.parse(server_url).to_hash.slice(:scheme, :host, :port)

      unless uri_hash[:port]
        uri_hash[:port] = (uri_hash[:scheme] == "https" ? 443 : 80)
      end

      if org_match = server_url.match(/.*\/organizations\/(.*)/)
        @organization = org_match[1]
      end

      unless @organization.nil?
        uri_hash[:path] = "/organizations/#{@organization}"
      end

      server_uri = Addressable::URI.new(uri_hash)

      super(server_uri, options)
    end

    # @return [Symbol]
    def api_type
      organization.nil? ? :foss : :hosted
    end

    # @return [Boolean]
    def hosted?
      api_type == :hosted
    end

    # @return [Boolean]
    def foss?
      api_type == :foss
    end

    def server_url
      self.url_prefix.to_s
    end

    # Stream the response body of a remote URL to a file on the local file system
    #
    # @param [String] target
    #   a URL to stream the response body from
    # @param [String] destination
    #   a location on disk to stream the content of the response body to
    def stream(target, destination)
      FileUtils.mkdir_p(File.dirname(destination))

      target  = Addressable::URI.parse(target)
      headers = Middleware::ChefAuth.authentication_headers(
        client_name,
        client_key,
        http_method: "GET",
        host: target.host,
        path: target.path
      )

      unless ssl[:verify]
        headers.merge!(ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
      end

      local = Tempfile.new('ridley-stream')
      local.binmode

      open(target, 'rb', headers) do |remote|
        local.write(remote.read)
      end
      
      FileUtils.mv(local.path, destination)
    ensure
      local.close(true) unless local.nil?
    end
  end
end
