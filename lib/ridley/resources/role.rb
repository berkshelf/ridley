module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Role
    include Ridley::Resource

    set_chef_id "name"
    set_chef_type "role"
    set_chef_json_class "Chef::Role"
    set_resource_path "roles"

    attribute :name
    validates_presence_of :name

    attribute :description, default: String.new
    attribute :default_attributes, default: Hash.new
    attribute :override_attributes, default: Hash.new
    attribute :run_list, default: Array.new
    attribute :env_run_lists, default: Hash.new
  end

  module DSL
    # Coerces instance functions into class functions on Ridley::Role. This coercion
    # sends an instance of the including class along to the class function.
    #
    # @see Ridley::Context
    #
    # @return [Ridley::Context]
    #   a context object to delegate instance functions to class functions on Ridley::Role
    def role
      Context.new(Ridley::Role, self)
    end
  end
end
