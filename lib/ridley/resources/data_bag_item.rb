require 'yaml'
require 'openssl'
require 'base64'

module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class DataBagItem
    include ActiveModel::Validations
    include ActiveModel::Serialization

    class << self
      # @param [Ridley::Connection] connection
      #
      # @return [Array<Object>]
      def all(connection, data_bag)
        connection.get("#{data_bag.class.resource_path}/#{data_bag.name}").body.collect do |id, location|
          new(connection, data_bag, id: id)
        end
      end

      # @param [Ridley::Connection] connection
      # @param [Ridley::DataBag] data_bag
      # @param [String, #chef_id] object
      #
      # @return [nil, Ridley::DataBagItem]
      def find(connection, data_bag, object)
        find!(connection, data_bag, object)
      rescue Errors::HTTPNotFound
        nil
      end

      # @param [Ridley::Connection] connection
      # @param [Ridley::DataBag] data_bag
      # @param [String, #chef_id] object
      #
      # @raise [Errors::HTTPNotFound]
      #   if a resource with the given chef_id is not found
      #
      # @return [Ridley::DataBagItem]
      def find!(connection, data_bag, object)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        new(connection, data_bag).from_hash(connection.get("#{data_bag.class.resource_path}/#{data_bag.name}/#{chef_id}").body)
      end

      # @param [Ridley::Connection] connection
      # @param [Ridley::DataBag] data_bag
      # @param [#to_hash] object
      #
      # @return [Ridley::DataBagItem]
      def create(connection, data_bag, object)
        resource = new(connection, data_bag, object.to_hash)
        unless resource.valid?
          raise Errors::InvalidResource.new(resource.errors)
        end

        new_attributes = connection.post("#{data_bag.class.resource_path}/#{data_bag.name}", resource.to_json).body
        resource.from_hash(resource.attributes.deep_merge(new_attributes))
        resource
      end

      # @param [Ridley::Connection] connection
      # @param [Ridley::DataBag] data_bag
      # @param [String, #chef_id] object
      #
      # @return [Ridley::DataBagItem]
      def delete(connection, data_bag, object)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        new(connection, data_bag).from_hash(connection.delete("#{data_bag.class.resource_path}/#{data_bag.name}/#{chef_id}").body)
      end

      # @param [Ridley::Connection] connection
      # @param [Ridley::DataBag] data_bag
      #
      # @return [Array<Ridley::DataBagItem>]
      def delete_all(connection, data_bag)
        mutex = Mutex.new
        deleted = []
        resources = all(connection, data_bag)

        connection.thread_count.times.collect do
          Thread.new(connection, data_bag, resources, deleted) do |connection, data_bag, resources, deleted|
            while resource = mutex.synchronize { resources.pop }
              result = delete(connection, data_bag, resource)
              mutex.synchronize { deleted << result }
            end
          end
        end.each(&:join)

        deleted
      end

      # @param [Ridley::Connection] connection
      # @param [Ridley::DataBag] data_bag
      # @param [#to_hash] object
      #
      # @return [Ridley::DataBagItem]
      def update(connection, data_bag, object)
        resource = new(connection, data_bag, object.to_hash)
        new(connection, data_bag).from_hash(
          connection.put("#{data_bag.class.resource_path}/#{data_bag.name}/#{resource.chef_id}", resource.to_json).body
        )
      end
    end

    # @return [Ridley::DataBag]
    attr_reader :data_bag
    # @return [HashWithIndifferentAccess]
    attr_reader :attributes

    validates_presence_of :id

    # @param [Ridley::Connection] connection
    # @param [Ridley::DataBag] data_bag
    # @param [#to_hash] attributes
    def initialize(connection, data_bag, attributes = {})
      @connection = connection
      @data_bag = data_bag
      self.attributes = attributes
    end

    # Alias for accessing the value of the 'id' attribute
    #
    # @return [String]
    def chef_id
      @attributes[:id]
    end
    alias_method :id, :chef_id

    # @param [String, Symbol] key
    #
    # @return [Object]
    def attribute(key)
      @attributes[key]
    end
    alias_method :[], :attribute

    # @param [String, Symbol] key
    # @param [Object] value
    #
    # @return [Object]
    def attribute=(key, value)
      @attributes[key] = value
    end
    alias_method :[]=, :attribute=

    # @param [#to_hash] new_attributes
    #
    # @return [HashWithIndifferentAccess]
    def attributes=(new_attributes)
      @attributes = HashWithIndifferentAccess.new(new_attributes.to_hash)
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

      self.attributes = self.class.create(connection, data_bag, self).attributes
      true
    rescue Errors::HTTPConflict
      self.attributes = self.class.update(connection, data_bag, self).attributes
      true
    end

    # Decrypts this data bag item.
    #
    # @return [Hash] decrypted attributes
    def decrypt
      decrypted_hash = Hash[attributes.map { |key, value| [key, decrypt_value(value)] }]
      self.attributes = HashWithIndifferentAccess.new(decrypted_hash)
    end

    def decrypt_value(value)
      decoded_value = Base64.decode64(value)

      cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
      cipher.decrypt
      cipher.pkcs5_keyivgen(connection.encrypted_data_bag_secret)
      decrypted_value = cipher.update(decoded_value)
      decrypted_value << cipher.final

      YAML.load(decrypted_value)
    end

    # @param [#to_hash] hash
    #
    # @return [Object]
    def from_hash(hash)
      hash = HashWithIndifferentAccess.new(hash.to_hash)

      self.attributes = hash.has_key?(:raw_data) ? hash[:raw_data] : hash
      self
    end

    # @option options [Boolean] :symbolize_keys
    # @option options [Class, Symbol, String] :adapter
    #
    # @return [String]
    def to_json(options = {})
      MultiJson.encode(self.attributes, options)
    end
    alias_method :as_json, :to_json

    def to_hash
      self.attributes
    end

    def to_s
      self.attributes
    end

    private

      # @return [Ridley::Connection]
      attr_reader :connection
  end
end
