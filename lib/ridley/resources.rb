Dir["#{File.dirname(__FILE__)}/resources/*.rb"].sort.each do |path|
  require "ridley/resources/#{File.basename(path, '.rb')}"
end
