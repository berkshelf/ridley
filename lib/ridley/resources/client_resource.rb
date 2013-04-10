module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  #
  # @example listing all clients
  #   conn = Ridley.new(...)
  #   conn.client.all #=> [
  #     #<Ridley::ClientResource chef_id:'reset'>,
  #     #<Ridley::ClientResource chef_id:'reset-validator'>
  #   ]
  class ClientResource < Ridley::Resource
    set_chef_id "name"
    set_chef_type "client"
    set_chef_json_class "Chef::ApiClient"
    set_resource_path "clients"
    represented_by Ridley::ClientObject

    # Retrieves a client from the remote connection matching the given chef_id
    # and regenerates it's private key. An instance of the updated object will
    # be returned and have a value set for the 'private_key' accessor.
    #
    # @param [String, #chef_id] chef_client
    #
    # @raise [Errors::HTTPNotFound]
    #   if a client with the given chef_id is not found
    # @raise [Errors::HTTPError]
    #
    # @return [Ridley::ClientResource]
    def regenerate_key(chef_client)
      obj = find!(chef_client)
      obj.regenerate_key
      obj
    end
  end
end
