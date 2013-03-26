Dir["#{File.dirname(__FILE__)}/bindings/*.rb"].sort.each do |path|
  require "ridley/bindings/#{File.basename(path, '.rb')}"
end
