module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Middleware
    CONTENT_TYPE = 'content-type'.freeze

    require 'ridley/middleware/parse_json'
    require 'ridley/middleware/chef_response'
    require 'ridley/middleware/chef_auth'
    require 'ridley/middleware/retry'

    Faraday.register_middleware :request,
      chef_auth: -> { Ridley::Middleware::ChefAuth }

    Faraday.register_middleware :request,
      retry: -> { Ridley::Middleware::Retry }

    Faraday.register_middleware :response,
      json: -> { Ridley::Middleware::ParseJson }

    Faraday.register_middleware :response,
      chef_response: -> { Ridley::Middleware::ChefResponse }
  end
end
