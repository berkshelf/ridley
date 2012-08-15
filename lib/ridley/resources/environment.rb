module Ridley
  class Environment
    module DSL
      def environment
        Ridley::Environment
      end
    end

    class << self
      def delete_all
        envs = all.reject { |env| env.name.to_s == '_default' }
        envs.collect { |obj| delete(obj) }
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
