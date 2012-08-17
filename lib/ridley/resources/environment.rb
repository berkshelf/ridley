module Ridley
  class Environment
    class << self
      # @param [Ridley::Connection] connection
      def delete_all(connection)
        envs = all(connection).reject { |env| env.name.to_s == '_default' }
        envs.collect { |obj| delete(connection, obj) }
      end
    end

    include Ridley::Resource

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
end
