module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class DataBag
    include Ridley::Resource
  end

  module DSL
    # Coerces instance functions into class functions on Ridley::DataBag. This coercion
    # sends an instance of the including class along to the class function.
    #
    # @see Ridley::Context
    #
    # @return [Ridley::Context]
    #   a context object to delegate instance functions to class functions on Ridley::DataBag
    def data_bag
      Context.new(Ridley::DataBag, self)
    end
  end
end
