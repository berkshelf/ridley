require 'yaml'
require 'yajl'

module Ridley
  class DataBagItemObject < ChefObject
    ALGORITHM = 'aes-256-cbc'
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

    # Encrypts attributes of this data bag item
    #
    # @return [Object]
    def encrypt_attributes
      self.attributes = Hash[_attributes_.map { |key, value| [key, key == "id" ? value : for_encrypted_item(value)] }]
      self
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
      case format_version_of(value)
      when 0
        decrypt_v0_value(value)
      when 1
        decrypt_v1_value(value)
      else
        raise NotImplementedError, "Currently decrypting only version 0 & 1 databags are supported"
      end
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

      # Shamelessly lifted from https://github.com/opscode/chef/blob/2c0040c95bb942d13ad8c47498df56be43e9a82e/lib/chef/encrypted_data_bag_item.rb#L209-L215
      def format_version_of(encrypted_value)
        if encrypted_value.respond_to?(:key?)
          encrypted_value["version"]
        else
          0
        end
      end

      def decrypt_v0_value(value)
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

      def decrypt_v1_value(attrs)
        if encrypted_data_bag_secret.nil?
          raise Errors::EncryptedDataBagSecretNotSet
        end

        cipher = OpenSSL::Cipher::Cipher.new(attrs[:cipher])
        cipher.decrypt
        cipher.key = Digest::SHA256.digest(encrypted_data_bag_secret)
        cipher.iv = Base64.decode64(attrs[:iv])
        decrypted_value = cipher.update(Base64.decode64(attrs[:encrypted_data])) + cipher.final

        YAML.load(decrypted_value)["json_wrapper"]
      end

      def encrypted_data_bag_secret
        resource.encrypted_data_bag_secret
      end

      # Shamelessly lifted from https://github.com/opscode/chef/blob/master/lib/chef/encrypted_data_bag_item/encryptor.rb

      # Returns a wrapped and encrypted version of +value+ suitable for
      # using as the value in an encrypted data bag item.
      def for_encrypted_item(value)
        {
            "encrypted_data" => encrypted_data(value),
            "iv" => Base64.encode64(iv),
            "version" => 1,
            "cipher" => ALGORITHM
        }
      end

      # Generates or returns the IV.
      def iv
        # Generated IV comes from OpenSSL::Cipher::Cipher#random_iv
        # This gets generated when +openssl_encryptor+ gets created.
        openssl_encryptor if @iv.nil?
        @iv
      end

      # Generates (and memoizes) an OpenSSL::Cipher::Cipher object and configures
      # it for the specified iv and encryption key.
      def openssl_encryptor
        @openssl_encryptor ||= begin
          encryptor = OpenSSL::Cipher::Cipher.new(ALGORITHM)
          encryptor.encrypt
          @iv ||= encryptor.random_iv.chomp
          encryptor.iv = @iv
          encryptor.key = Digest::SHA256.digest(encrypted_data_bag_secret)
          encryptor
        end
      end

      # Encrypts and Base64 encodes +serialized_data+
      def encrypted_data(value)
        openssl_encryptor.reset
        enc_data = openssl_encryptor.update(serialized_data(value))
        enc_data << openssl_encryptor.final
        Base64.encode64(enc_data)
      end

      # Wraps the data in a single key Hash (JSON Object) and converts to JSON.
      # The wrapper is required because we accept values (such as Integers or
      # Strings) that do not produce valid JSON when serialized without the
      # wrapper.
      def serialized_data(value)
        Yajl::Encoder.encode(:json_wrapper => value)
      end
  end
end
