module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  module Errors
    class RidleyError < StandardError; end
    class InternalError < RidleyError; end
    class ArgumentError < InternalError; end

    class ResourceNotFound < RidleyError; end
    class ValidatorNotFound < RidleyError; end

    class InvalidResource < RidleyError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
      end

      def message
        errors.values
      end
      alias_method :to_s, :message
    end

    class UnknownCookbookFileType < RidleyError
      attr_reader :type

      def initialize(type)
        @type = type
      end

      def to_s
        "filetype: '#{type}'"
      end
    end

    class CookbookSyntaxError < RidleyError; end

    class BootstrapError < RidleyError; end
    class ClientKeyFileNotFound < BootstrapError; end
    class EncryptedDataBagSecretNotFound < BootstrapError; end

    # Exception thrown when the maximum amount of requests is exceeded.
    class RedirectLimitReached < RidleyError
      attr_reader :response

      def initialize(response)
        super "too many redirects; last one to: #{response['location']}"
        @response = response
      end
    end

    class FrozenCookbook < RidleyError; end

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

    class HTTP3XXError < HTTPError; end
    class HTTP4XXError < HTTPError; end
    class HTTP5XXError < HTTPError; end

    # 3XX
    class HTTPMovedPermanently < HTTP3XXError; register_error(301); end
    class HTTPFound < HTTP3XXError; register_error(302); end

    # 4XX
    class HTTPBadRequest < HTTP4XXError; register_error(400); end
    class HTTPUnauthorized < HTTP4XXError; register_error(401); end
    class HTTPForbidden < HTTP4XXError; register_error(403); end
    class HTTPNotFound < HTTP4XXError; register_error(404); end
    class HTTPMethodNotAllowed < HTTP4XXError; register_error(405); end
    class HTTPRequestTimeout < HTTP4XXError; register_error(408); end
    class HTTPConflict < HTTP4XXError; register_error(409); end

    # 5XX
    class HTTPInternalServerError < HTTP5XXError; register_error(500); end
    class HTTPNotImplemented < HTTP5XXError; register_error(501); end
    class HTTPBadGateway < HTTP5XXError; register_error(502); end
    class HTTPServiceUnavailable < HTTP5XXError; register_error(503); end
    class HTTPGatewayTimeout < HTTP5XXError; register_error(504); end
  end
end
