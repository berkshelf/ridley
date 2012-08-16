module Ridley
  class Client
    module DSL
      def client
        Ridley::Client
      end
    end

    include Ridley::Resource

    class << self
      # Retrieves a client from the remote connection matching the given chef_id
      # and regenerates it's private key. An instance of the updated object will
      # be returned and have a value set for the 'private_key' accessor.
      #
      # @param [String, #chef_id] client
      #
      # @raise [Errors::HTTPNotFound]
      #   if a client with the given chef_id is not found
      # @raise [Errors::HTTPError]
      #
      # @return [Ridley::Client]
      def regenerate_key(client)
        obj = find!(client)
        obj.regenerate_key
        obj
      end
    end

    set_chef_id "name"
    set_chef_type "client"
    set_chef_json_class "Chef::ApiClient"
    set_resource_path "clients"

    attribute :name
    validates_presence_of :name

    attribute :admin, default: false
    validates_inclusion_of :admin, in: [ true, false ]

    attribute :validator, default: false
    validates_inclusion_of :validator, in: [ true, false ]

    attribute :certificate
    attribute :public_key
    attribute :private_key
    attribute :orgname

    def attributes
      super.except(:json_class)
    end

    # Regenerates the private key of the instantiated client object. The new
    # private key will be set to the value of the 'private_key' accessor
    # of the instantiated client object.
    #
    # @return [Boolean]
    #   true for success and false for failure
    def regenerate_key
      self.private_key = true
      self.save
    end
  end
end
