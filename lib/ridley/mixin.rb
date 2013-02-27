Dir["#{File.dirname(__FILE__)}/mixin/*.rb"].sort.each do |path|
  require "ridley/mixin/#{File.basename(path, '.rb')}"
end
