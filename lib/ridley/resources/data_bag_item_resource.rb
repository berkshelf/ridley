module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class DataBagItemResource < Ridley::Resource
    class << self
      # @param [Ridley::Client] client
      #
      # @return [Array<Object>]
      def all(client, data_bag)
        client.connection.get("#{data_bag.class.resource_path}/#{data_bag.name}").body.collect do |id, location|
          new(client, data_bag, id: id)
        end
      end

      # @param [Ridley::Client] client
      # @param [Ridley::DataBagResource] data_bag
      # @param [String, #chef_id] object
      #
      # @return [nil, Ridley::DataBagItemResource]
      def find(client, data_bag, object)
        find!(client, data_bag, object)
      rescue Errors::HTTPNotFound
        nil
      end

      # @param [Ridley::Client] client
      # @param [Ridley::DataBagResource] data_bag
      # @param [String, #chef_id] object
      #
      # @raise [Errors::HTTPNotFound]
      #   if a resource with the given chef_id is not found
      #
      # @return [Ridley::DataBagItemResource]
      def find!(client, data_bag, object)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        new(client, data_bag).from_hash(client.connection.get("#{data_bag.class.resource_path}/#{data_bag.name}/#{chef_id}").body)
      end

      # @param [Ridley::Client] client
      # @param [Ridley::DataBagResource] data_bag
      # @param [#to_hash] object
      #
      # @return [Ridley::DataBagItemResource]
      def create(client, data_bag, object)
        resource = new(client, data_bag, object.to_hash)
        unless resource.valid?
          raise Errors::InvalidResource.new(resource.errors)
        end

        new_attributes = client.connection.post("#{data_bag.class.resource_path}/#{data_bag.name}", resource.to_json).body
        resource.mass_assign(new_attributes)
        resource
      end

      # @param [Ridley::Client] client
      # @param [Ridley::DataBagResource] data_bag
      # @param [String, #chef_id] object
      #
      # @return [Ridley::DataBagItemResource]
      def delete(client, data_bag, object)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        new(client, data_bag).from_hash(client.connection.delete("#{data_bag.class.resource_path}/#{data_bag.name}/#{chef_id}").body)
      end

      # @param [Ridley::Client] client
      # @param [Ridley::DataBagResource] data_bag
      #
      # @return [Array<Ridley::DataBagItemResource>]
      def delete_all(client, data_bag)
        mutex = Mutex.new
        deleted = []

        all(client, data_bag).collect do |resource|
          Celluloid::Future.new {
            delete(client, data_bag, resource)
          }
        end.map(&:value)
      end

      # @param [Ridley::Client] client
      # @param [Ridley::DataBagResource] data_bag
      # @param [#to_hash] object
      #
      # @return [Ridley::DataBagItemResource]
      def update(client, data_bag, object)
        resource = new(client, data_bag, object.to_hash)
        new(client, data_bag).from_hash(
          client.connection.put("#{data_bag.class.resource_path}/#{data_bag.name}/#{resource.chef_id}", resource.to_json).body
        )
      end
    end

    set_assignment_mode :carefree

    # @return [Ridley::DataBagResource]
    attr_reader :data_bag

    attribute :id,
      type: String,
      required: true

    alias_method :attributes=, :mass_assign
    alias_method :attributes, :_attributes_

    # @param [Ridley::Client] client
    # @param [Ridley::DataBagResource] data_bag
    # @param [#to_hash] new_attrs
    def initialize(client, data_bag, new_attrs = {})
      super(client, new_attrs)
      @data_bag = data_bag
    end

    # Alias for accessing the value of the 'id' attribute
    #
    # @return [String]
    def chef_id
      get_attribute(:id)
    end

    # Creates a resource on the target remote or updates one if the resource
    # already exists.
    #
    # @raise [Errors::InvalidResource]
    #   if the resource does not pass validations
    #
    # @return [Boolean]
    #   true if successful and false for failure
    def save
      raise Errors::InvalidResource.new(self.errors) unless valid?

      mass_assign(self.class.create(client, data_bag, self)._attributes_)
      true
    rescue Errors::HTTPConflict
      self.update
      true
    end

    # Decrypts this data bag item.
    #
    # @return [Hash] decrypted attributes
    def decrypt
      decrypted_hash = Hash[_attributes_.map { |key, value| [key, key == "id" ? value : decrypt_value(value)] }]
      mass_assign(decrypted_hash)
    end

    def decrypt_value(value)
      decoded_value = Base64.decode64(value)

      cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
      cipher.decrypt
      cipher.pkcs5_keyivgen(client.encrypted_data_bag_secret)
      decrypted_value = cipher.update(decoded_value) + cipher.final

      YAML.load(decrypted_value)
    end

    # Reload the attributes of the instantiated resource
    #
    # @return [Object]
    def reload
      mass_assign(self.class.find(client, data_bag, self)._attributes_)
      self
    end

    # Updates the instantiated resource on the target remote with any changes made
    # to self
    #
    # @raise [Errors::InvalidResource]
    #   if the resource does not pass validations
    #
    # @return [Boolean]
    def update
      raise Errors::InvalidResource.new(self.errors) unless valid?

      mass_assign(self.class.update(client, data_bag, self)._attributes_)
      true
    end

    # @param [#to_hash] hash
    #
    # @return [Object]
    def from_hash(hash)
      hash = Hashie::Mash.new(hash.to_hash)

      mass_assign(hash.has_key?(:raw_data) ? hash[:raw_data] : hash)
      self
    end
  end
end
