require 'ridley/mixin/bootstrap_binding'

Dir["#{File.dirname(__FILE__)}/bootstrap_bindings/*.rb"].sort.each do |path|
  require "ridley/bootstrap_bindings/#{File.basename(path, '.rb')}"
end
