module Ridley
  module Middleware
    CONTENT_TYPE     = 'content-type'.freeze
    CONTENT_ENCODING = 'content-encoding'.freeze
  end
end

Dir["#{File.dirname(__FILE__)}/middleware/*.rb"].sort.each do |path|
  require_relative "middleware/#{File.basename(path, '.rb')}"
end
