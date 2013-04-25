module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class DataBagItemObject < ChefObject
    set_chef_id "id"
    set_assignment_mode :carefree

    # @return [Ridley::DataBagObject]
    attr_reader :data_bag

    attribute :id,
      type: String,
      required: true

    alias_method :attributes=, :mass_assign
    alias_method :attributes, :_attributes_

    # @param [Ridley::DataBagItemResource] resource
    # @param [Ridley::DataBagObject] data_bag
    # @param [#to_hash] new_attrs
    def initialize(resource, data_bag, new_attrs = {})
      super(resource, new_attrs)
      @data_bag = data_bag
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

      mass_assign(resource.create(data_bag, self)._attributes_)
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

    # Decrypts an individual value stored inside the data bag item.
    #
    # @example
    #   data_bag_item.decrypt_value("Xk0E8lV9r4BhZzcg4wal0X4w9ZexN3azxMjZ9r1MCZc=") 
    #     => {test: {database: {username: "test"}}}
    #
    # @param [String] an encrypted String value
    #
    # @return [Hash] a decrypted attribute value
    def decrypt_value(value)
      if encrypted_data_bag_secret.nil?
        raise Errors::EncryptedDataBagSecretNotSet
      end

      decoded_value = Base64.decode64(value)

      cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
      cipher.decrypt
      cipher.pkcs5_keyivgen(encrypted_data_bag_secret)
      decrypted_value = cipher.update(decoded_value) + cipher.final

      YAML.load(decrypted_value)
    end

    # Reload the attributes of the instantiated resource
    #
    # @return [Object]
    def reload
      mass_assign(resource.find(data_bag, self)._attributes_)
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

      mass_assign(resource.update(data_bag, self)._attributes_)
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

    private

      def encrypted_data_bag_secret
        resource.encrypted_data_bag_secret
      end
  end
end
