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

    # @param [String] :server_url
    # @param [String] :client_name
    # @param [String] :client_key
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
      options = options.reverse_merge(
        url: server_url,
        builder: Faraday::Builder.new { |b|
          b.adapter :net_http_persistent
          b.request :chef_auth, client_name, client_key
          b.response :chef_response
          b.response :json
        }
      )

      super(options)
    end

    def server_url
      self.url_prefix.to_s
    end
  end
end
