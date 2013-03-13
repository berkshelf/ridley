module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  # @api private
  class ChainLink
    attr_reader :parent
    attr_reader :child

    # @param [Class, Object] parent
    #   the parent class or object to send to the child
    # @param [Class, Object] child
    #   the child class or instance to delegate functions to
    def initialize(parent, child)
      @parent = parent
      @child  = child
    end

    def new(*args)
      child.send(:new, parent, *args)
    end

    def method_missing(fun, *args, &block)
      child.send(fun, parent, *args, &block)
    end
  end
end
