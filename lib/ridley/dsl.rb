module Ridley
  # @api public
  # @author Jamie Winsor <jamie@vialstudios.com>
  #
  # A DSL to be included into Ridley::Connection. Instance functions of the same name as
  # Chef a resource are coerced into class functions of a class of the same name.
  #
  # This is accomplished by returning a Ridley::Context object and coercing any messages sent
  # to it into a message to the Chef resource's class in Ridley.
  #
  # @example
  #   class Connection
  #     include Ridley::DSL
  #   end
  #
  #   connection = Ridley::Connection.new
  #   connection.role.all
  #
  #   The 'role' function is made available to the instance of Ridley::Connection by including
  #   Ridley::DSL. This function returns a Ridley::Context object which receives the 'all' message.
  #   The Ridley::Context coerces the 'all' message into a message to the Ridley::Role class and
  #   sends along the instance of Ridley::Connection that is chaining 'role.all'
  #
  #   connection.role.all => Ridley::Role.all(connection)
  #
  #   Any additional arguments will also be passed to the class function of the Chef resource's class
  #
  #   connection.role.find("reset") => Ridley::Role.find(connection, "reset")
  #
  # @example instantiating new resources
  #   class connection
  #     include Ridley::DSL
  #   end
  #
  #   connection = Ridley::Connection.new
  #   connection.role.new(name: "hello") => <#Ridley::Role: @name="hello">
  #
  #   New instances of resources can be instantiated by calling new on the Ridley::Context. These messages
  #   will be send to the Chef resource's class in Ridley and can be treated as a normal Ruby object. Each
  #   instantiated object will have the connection information contained within so you can do things like
  #   save a role after changing it's attributes.
  #
  #   r = connection.role.new(name: "new-role")
  #   r.name => "new-role"
  #   r.name = "other-name"
  #   r.save
  #
  #   connection.role.find("new-role") => <#Ridley::Role: @name="new-role">
  #
  # @see Ridley::Context
  # @see Ridley::Role
  # @see Ridley::Connection
  module DSL; end
end

Dir["#{File.dirname(__FILE__)}/resources/*.rb"].sort.each do |path|
  require "ridley/resources/#{File.basename(path, '.rb')}"
end
