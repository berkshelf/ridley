module Ridley
  class Client
    module DSL
      def client
        Ridley::Client
      end
    end

    include Ridley::Resource

    set_chef_id "name"
    set_chef_type "client"
    set_chef_json_class "Chef::ApiClient"
    set_resource_path "clients"

    attribute :name
    validates_presence_of :name

    attribute :admin, default: false
    validates_presence_of :admin

    attribute :public_key
    attribute :private_key
  end
end
