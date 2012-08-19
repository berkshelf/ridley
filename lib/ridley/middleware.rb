module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Middleware
    CONTENT_TYPE = 'content-type'.freeze

    require 'ridley/middleware/parse_json'
    require 'ridley/middleware/chef_response'
    require 'ridley/middleware/chef_auth'

    Faraday.register_middleware :request,
      chef_auth: -> { ChefAuth }

    Faraday.register_middleware :response,
      json: -> { ParseJson }

    Faraday.register_middleware :response,
      chef_response: -> { ChefResponse }
  end
end
