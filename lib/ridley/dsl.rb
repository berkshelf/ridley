module Ridley
  module DSL
    def client
      Context.new(Ridley::Client, self)
    end

    def cookbook
      Context.new(Ridley::Cookbook, self)
    end

    def data_bag
      Context.new(Ridley::DataBag, self)
    end

    def environment
      Context.new(Ridley::Environment, self)
    end
    
    def node
      Context.new(Ridley::Node, self)
    end
    
    def role
      Context.new(Ridley::Node, self)
    end
  end
end
