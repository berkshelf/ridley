require 'zlib'

module Ridley
  module Middleware
    class Gzip < Faraday::Response::Middleware
      def on_complete(env)
        case env[:response_headers][CONTENT_ENCODING].to_s.downcase
        when 'gzip'
          env[:body] = Zlib::GzipReader.new(StringIO.new(env[:body]), encoding: 'ASCII-8BIT').read
        when 'deflate'
          env[:body] = Zlib::Inflate.inflate(env[:body])
        end
      end
    end
  end
end

Faraday::Response.register_middleware gzip: Ridley::Middleware::Gzip
