require 'httpclient/webagent-cookie'

module Ridley
  module HTTPClientExt
    module WebAgent
      module Cookie
        def domain
          self.original_domain
        end
      end
    end
  end
end
