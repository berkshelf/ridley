module Ridley
  # @example listing all clients
  #   conn = Ridley.new(...)
  #   conn.client.all #=> [
  #     #<Ridley::ClientObject chef_id:'reset'>,
  #     #<Ridley::ClientObject chef_id:'reset-validator'>
  #   ]
  class ClientResource < Ridley::Resource
    set_resource_path "clients"
    represented_by Ridley::ClientObject

    # Retrieves a client from the remote connection matching the given chef_id
    # and regenerates its private key. An instance of the updated object will
    # be returned and will have a value set for the 'private_key' accessor.
    #
    # @param [String, #chef_id] chef_client
    #
    # @raise [Errors::ResourceNotFound]
    #   if a client with the given chef_id is not found
    #
    # @return [Ridley::ClientObject]
    def regenerate_key(chef_client)
      unless chef_client = find(chef_client)
        abort Errors::ResourceNotFound.new("client '#{chef_client}' not found")
      end

      chef_client.private_key = true
      update(chef_client)
    end
  end
end
