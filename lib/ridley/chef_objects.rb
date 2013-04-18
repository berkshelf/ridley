Dir["#{File.dirname(__FILE__)}/chef_objects/*.rb"].sort.each do |path|
  require "ridley/chef_objects/#{File.basename(path, '.rb')}"
end
