module Ridley
  module Errors
    class RidleyError < StandardError; end
    class InternalError < RidleyError; end
    class ArgumentError < InternalError; end

    class ClientError < RidleyError; end
    class ConnectionFailed < ClientError; end
    class TimeoutError < ClientError; end

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
    class EncryptedDataBagSecretNotSet < RidleyError
      def message
        "no encrypted data bag secret was set for this Ridley connection"
      end
    end

    class BootstrapError < RidleyError; end
    class ClientKeyFileNotFoundOrInvalid < BootstrapError; end
    class EncryptedDataBagSecretNotFound < BootstrapError; end

    class HostConnectionError < RidleyError; end
    class DNSResolvError < HostConnectionError; end

    class RemoteCommandError < RidleyError; end
    class RemoteScriptError < RemoteCommandError; end
    class CommandNotProvided < RemoteCommandError
      attr_reader :connector_type

      # @params [Symbol] connector_type
      def initialize(connector_type)
        @connector_type = connector_type
      end

      def to_s
        "No command provided in #{connector_type.inspect}, however the #{connector_type.inspect} connector was selected."
      end
    end

    # Exception thrown when the maximum amount of requests is exceeded.
    class RedirectLimitReached < RidleyError
      attr_reader :response

      def initialize(response)
        super "too many redirects; last one to: #{response['location']}"
        @response = response
      end
    end

    class FrozenCookbook < RidleyError; end
    class SandboxCommitError < RidleyError; end
    class PermissionDenied < RidleyError; end

    class SandboxUploadError < RidleyError; end
    class ChecksumMismatch < RidleyError; end

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

    class HTTPUnknownMethod < HTTPError
      attr_reader :method

      def initialize(method)
        @method  = method
        @message = "unknown http method: #{method}"
      end
    end

    class HTTP3XXError < HTTPError; end
    class HTTP4XXError < HTTPError; end
    class HTTP5XXError < HTTPError; end

    # 3XX
    class HTTPMultipleChoices < HTTP3XXError; register_error(300); end
    class HTTPMovedPermanently < HTTP3XXError; register_error(301); end
    class HTTPFound < HTTP3XXError; register_error(302); end
    class HTTPSeeOther < HTTP3XXError; register_error(303); end
    class HTTPNotModified < HTTP3XXError; register_error(304); end
    class HTTPUseProxy < HTTP3XXError; register_error(305); end
    class HTTPTemporaryRedirect < HTTP3XXError; register_error(307); end

    # 4XX
    class HTTPBadRequest < HTTP4XXError; register_error(400); end
    class HTTPUnauthorized < HTTP4XXError; register_error(401); end
    class HTTPPaymentRequired < HTTP4XXError; register_error(402); end
    class HTTPForbidden < HTTP4XXError; register_error(403); end
    class HTTPNotFound < HTTP4XXError; register_error(404); end
    class HTTPMethodNotAllowed < HTTP4XXError; register_error(405); end
    class HTTPNotAcceptable < HTTP4XXError; register_error(406); end
    class HTTPProxyAuthenticationRequired < HTTP4XXError; register_error(407); end
    class HTTPRequestTimeout < HTTP4XXError; register_error(408); end
    class HTTPConflict < HTTP4XXError; register_error(409); end
    class HTTPGone < HTTP4XXError; register_error(410); end
    class HTTPLengthRequired < HTTP4XXError; register_error(411); end
    class HTTPPreconditionFailed < HTTP4XXError; register_error(412); end
    class HTTPRequestEntityTooLarge < HTTP4XXError; register_error(413); end
    class HTTPRequestURITooLong < HTTP4XXError; register_error(414); end
    class HTTPUnsupportedMediaType < HTTP4XXError; register_error(415); end

    # 5XX
    class HTTPInternalServerError < HTTP5XXError; register_error(500); end
    class HTTPNotImplemented < HTTP5XXError; register_error(501); end
    class HTTPBadGateway < HTTP5XXError; register_error(502); end
    class HTTPServiceUnavailable < HTTP5XXError; register_error(503); end
    class HTTPGatewayTimeout < HTTP5XXError; register_error(504); end
  end
end
