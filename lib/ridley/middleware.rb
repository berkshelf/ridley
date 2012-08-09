module Ridley
  module Middleware
    require 'ridley/middleware/chef_response'
    require 'ridley/middleware/chef_auth'

    Faraday.register_middleware :request,
      chef_auth: -> { ChefAuth }

    Faraday.register_middleware :response,
      chef_response: -> { ChefResponse }
  end
end
