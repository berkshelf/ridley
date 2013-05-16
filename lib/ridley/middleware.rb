module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  module Middleware
    CONTENT_TYPE = 'content-type'.freeze

    require_relative 'middleware/parse_json'
    require_relative 'middleware/chef_response'
    require_relative 'middleware/chef_auth'
    require_relative 'middleware/follow_redirects'
    require_relative 'middleware/retry'

    Faraday.register_middleware :request,
      chef_auth: -> { Ridley::Middleware::ChefAuth }

    Faraday.register_middleware :request,
      retry: -> { Ridley::Middleware::Retry }

    Faraday.register_middleware :response,
      json: -> { Ridley::Middleware::ParseJson }

    Faraday.register_middleware :response,
      follow_redirects: -> { Ridley::Middleware::FollowRedirects }

    Faraday.register_middleware :response,
      chef_response: -> { Ridley::Middleware::ChefResponse }
  end
end
