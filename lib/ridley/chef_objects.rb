Dir["#{File.dirname(__FILE__)}/chef_objects/*.rb"].sort.each do |path|
  require_relative "chef_objects/#{File.basename(path, '.rb')}"
end
