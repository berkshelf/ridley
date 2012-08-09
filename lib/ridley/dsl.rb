module Ridley
  module DSL
    include Client::DSL
    include Cookbook::DSL
    include DataBag::DSL
    include Environment::DSL
    include Node::DSL
    include Role::DSL
  end
end
