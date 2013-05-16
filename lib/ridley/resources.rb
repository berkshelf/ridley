Dir["#{File.dirname(__FILE__)}/resources/*.rb"].sort.each do |path|
  require_relative "resources/#{File.basename(path, '.rb')}"
end
