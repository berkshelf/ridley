module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Errors
    class RidleyError < StandardError; end
    class InternalError < RidleyError; end

    class InvalidResource < RidleyError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
      end

      def message
        errors.full_messages.join(', ')
      end
      alias_method :to_s, :message
    end

    class HTTPError < RidleyError
      class << self
        def fabricate(env)
          klass = lookup_error(env[:status].to_i)
          klass.new(env)
        end

        def register_error(status)
          error_map[status.to_i] = self
        end

        def lookup_error(status)
          error_map.fetch(status.to_i)
        rescue KeyError
          HTTPUnknownStatus
        end

        def error_map
          @@error_map ||= Hash.new
        end        
      end

      attr_reader :env
      attr_reader :errors

      attr_reader :message
      alias_method :to_s, :message

      def initialize(env)
        @env = env
        @errors = env[:body].is_a?(Hash) ? Array(env[:body][:error]) : []

        if errors.empty?
          @message = env[:body] || "no content body"
        else
          @message = "errors: "
          @message << errors.collect { |e| "'#{e}'" }.join(', ')
        end
      end
    end

    class HTTPUnknownStatus < HTTPError
      def initialize(env)
        super(env)
        @message = "status: #{env[:status]} is an unknown HTTP status code or not an error."
      end
    end

    class HTTPBadRequest < HTTPError; register_error(400); end
    class HTTPUnauthorized < HTTPError; register_error(401); end
    class HTTPForbidden < HTTPError; register_error(403); end
    class HTTPNotFound < HTTPError; register_error(404); end
    class HTTPMethodNotAllowed < HTTPError; register_error(405); end
    class HTTPRequestTimeout < HTTPError; register_error(408); end
    class HTTPConflict < HTTPError; register_error(409); end
    
    class HTTPInternalServerError < HTTPError; register_error(500); end
    class HTTPNotImplemented < HTTPError; register_error(501); end
    class HTTPBadGateway < HTTPError; register_error(502); end
    class HTTPServiceUnavailable < HTTPError; register_error(503); end
    class HTTPGatewayTimeout < HTTPError; register_error(504); end
  end
end
