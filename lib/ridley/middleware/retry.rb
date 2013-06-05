module Ridley
  # Catches exceptions and retries each request a limited number of times.
  #
  # @example
  #
  #   Faraday.new do |conn|
  #     conn.request :retry, max: 2, interval: 0.05, exceptions: [CustomException, Faraday::Timeout::Error]
  #     conn.adapter ...
  #   end
  #
  # @note Borrowed and modified from: {https://github.com/lostisland/faraday/blob/master/lib/faraday/request/retry.rb}
  #   use the Faraday official middleware after the release of 0.9.x
  class Middleware::Retry < Faraday::Middleware
    # @option options [Integer] :max
    #   maximum number of retries
    # @option options [Float] :interval
    #   pause in seconds between retries
    # @option options [Array] :exceptions
    #   the list of exceptions to handle
    def initialize(app, options = {})
      super(app)
      @options  = options.slice(:max, :interval, :exceptions)
      @errmatch = build_exception_matcher(@options[:exceptions])
    end

    def call(env)
      retries = @options[:max]
      begin
        @app.call(env)
      rescue @errmatch
        if retries > 0
          retries -= 1
          sleep @options[:interval] if @options[:interval] > 0
          retry
        end
        raise
      end
    end

    # construct an exception matcher object.
    #
    # An exception matcher for the rescue clause can usually be any object that
    # responds to `===`, but for Ruby 1.8 it has to be a Class or Module.
    def build_exception_matcher(exceptions)
      matcher = Module.new
      (class << matcher; self; end).class_eval do
        define_method(:===) do |error|
          exceptions.any? do |ex|
            if ex.is_a? Module then error.is_a? ex
            else error.class.to_s == ex.to_s
            end
          end
        end
      end
      matcher
    end
  end
end

Faraday.register_middleware(:request, retry: Ridley::Middleware::Retry)
