module Ridley
  class Cookbook
    module DSL
      def cookbook
        Ridley::Cookbook
      end
    end
    
    include Ridley::Resource
  end
end
