module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class ClientResource < Ridley::Resource
    class << self
      # Retrieves a client from the remote connection matching the given chef_id
      # and regenerates it's private key. An instance of the updated object will
      # be returned and have a value set for the 'private_key' accessor.
      #
      # @param [Ridley::Client] client
      # @param [String, #chef_id] chef_client
      #
      # @raise [Errors::HTTPNotFound]
      #   if a client with the given chef_id is not found
      # @raise [Errors::HTTPError]
      #
      # @return [Ridley::ClientResource]
      def regenerate_key(client, chef_client)
        obj = find!(client, chef_client)
        obj.regenerate_key
        obj
      end
    end

    set_chef_id "name"
    set_chef_type "client"
    set_chef_json_class "Chef::ApiClient"
    set_resource_path "clients"

    attribute :name,
      type: String,
      required: true

    attribute :admin,
      type: Boolean,
      required: true,
      default: false

    attribute :validator,
      type: Boolean,
      required: true,
      default: false

    attribute :certificate,
      type: String

    attribute :public_key,
      type: String

    attribute :private_key,
      type: [ String, Boolean ]

    attribute :orgname,
      type: String

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

    # Override to_json to reflect to massage the returned attributes based on the type
    # of connection. Only OHC/OPC requires the json_class attribute is not present.
    def to_json
      if client.connection.hosted?
        to_hash.except(:json_class).to_json
      else
        super
      end
    end
  end
end
