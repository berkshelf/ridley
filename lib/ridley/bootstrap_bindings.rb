Dir["#{File.dirname(__FILE__)}/bootstrap_bindings/*.rb"].sort.each do |path|
  require_relative "bootstrap_bindings/#{File.basename(path, '.rb')}"
end
