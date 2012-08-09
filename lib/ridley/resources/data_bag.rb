module Ridley
  class DataBag
    module DSL
      def data_bag
        Ridley::DataBag
      end
    end

    include Ridley::Resource
  end
end
