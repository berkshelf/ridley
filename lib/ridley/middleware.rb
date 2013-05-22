module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  module Middleware
    CONTENT_TYPE     = 'content-type'.freeze
    CONTENT_ENCODING = 'content-encoding'.freeze
  end
end

Dir["#{File.dirname(__FILE__)}/middleware/*.rb"].sort.each do |path|
  require_relative "middleware/#{File.basename(path, '.rb')}"
end
