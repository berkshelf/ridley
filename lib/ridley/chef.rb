module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  #
  # Classes and modules used for integrating with a Chef Server, the Chef community
  # site, and Chef Cookbooks
  module Chef
    autoload :Cookbook, 'ridley/chef/cookbook'
    autoload :Chefignore, 'ridley/chef/chefignore'
    autoload :Digester, 'ridley/chef/digester'
  end
end
