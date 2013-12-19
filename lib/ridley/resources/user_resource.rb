module Ridley
  # @example listing all users
  #   conn = Ridley.new(...)
  #   conn.user.all #=> [
  #     #<Ridley::UserObject chef_id:'admin'>
  #   ]
  class UserResource < Ridley::Resource
    set_resource_path "users"
    represented_by Ridley::UserObject

    # Retrieves a user from the remote connection matching the given chef_id
    # and regenerates its private key. An instance of the updated object will
    # be returned and will have a value set for the 'private_key' accessor.
    #
    # @param [String, #chef_id] chef_user
    #
    # @raise [Errors::ResourceNotFound]
    #   if a user with the given chef_id is not found
    #
    # @return [Ridley::UserObject]
    def regenerate_key(chef_user)
      unless chef_user = find(chef_user)
        abort Errors::ResourceNotFound.new("user '#{chef_user}' not found")
      end

      chef_user.private_key = true
      update(chef_user)
    end

    def authenticate(username, password)
      resp = request(:post, '/authenticate_user', {'name' => username, 'password' => password}.to_json)
      abort("Username mismatch: sent #{username}, received #{resp['name']}") unless resp['name'] == username
      resp['verified']
    end
  end
end
