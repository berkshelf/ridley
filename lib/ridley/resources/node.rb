module Ridley
  class Node
    module DSL
      def node
        Ridley::Node
      end
    end

    include Ridley::Resource
  end
end
