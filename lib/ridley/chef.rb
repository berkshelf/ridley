module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  #
  # Classes and modules used for integrating with a Chef Server, the Chef community
  # site, and Chef Cookbooks
  module Chef
    autoload :Cookbook, 'ridley/chef/cookbook'
    autoload :Digester, 'ridley/chef/digester'
  end
end
