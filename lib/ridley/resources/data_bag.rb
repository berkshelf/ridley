module Ridley
  class DataBag
    include Ridley::Resource
  end

  module DSL
    def data_bag
      Context.new(Ridley::DataBag, self)
    end
  end
end
