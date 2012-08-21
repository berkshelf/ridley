module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Environment
    include Ridley::Resource
    
    class << self
      # Delete all of the environments on the remote connection. The
      # '_default' environment will never be deleted.
      #
      # @param [Ridley::Connection] connection
      #
      # @return [Array<Ridley::Environment>]
      def delete_all(connection)
        envs = all(connection).reject { |env| env.name.to_s == '_default' }
        envs.collect { |obj| delete(connection, obj) }
      end
    end

    set_chef_id "name"
    set_chef_type "environment"
    set_chef_json_class "Chef::Environment"
    set_resource_path "environments"

    attribute :name
    validates_presence_of :name

    attribute :description, default: String.new
    attribute :default_attributes, default: Hash.new
    attribute :override_attributes, default: Hash.new
    attribute :cookbook_versions, default: Hash.new
  end

  module DSL
    # Coerces instance functions into class functions on Ridley::Environment. This coercion
    # sends an instance of the including class along to the class function.
    #
    # @see Ridley::Context
    #
    # @return [Ridley::Context]
    #   a context object to delegate instance functions to class functions on Ridley::Environment
    def environment
      Context.new(Ridley::Environment, self)
    end
  end
end
