module Ridley
  class ClientObject < Ridley::ChefObject
    set_chef_id "name"
    set_chef_type "client"
    set_chef_json_class "Chef::ApiClient"

    attribute :name,
      type: String,
      required: true

    attribute :admin,
      type: Buff::Boolean,
      required: true,
      default: false

    attribute :validator,
      type: Buff::Boolean,
      required: true,
      default: false

    attribute :certificate,
      type: String

    attribute :public_key,
      type: String

    attribute :private_key,
      type: [ String, Buff::Boolean ],
      default: false

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
      if resource.connection.hosted?
        to_hash.except(:json_class).to_json
      else
        super
      end
    end
  end
end
