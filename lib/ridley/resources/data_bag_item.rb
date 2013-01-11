module Ridley
  # @author Jamie Winsor <jamie@vialstudios.com>
  class DataBagItem < Ridley::Resource
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
      # @param [Ridley::DataBagResource] data_bag
      # @param [String, #chef_id] object
      #
      # @return [nil, Ridley::DataBagItem]
      def find(connection, data_bag, object)
        find!(connection, data_bag, object)
      rescue Errors::HTTPNotFound
        nil
      end

      # @param [Ridley::Connection] connection
      # @param [Ridley::DataBagResource] data_bag
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
      # @param [Ridley::DataBagResource] data_bag
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
      # @param [Ridley::DataBagResource] data_bag
      # @param [String, #chef_id] object
      #
      # @return [Ridley::DataBagItem]
      def delete(connection, data_bag, object)
        chef_id = object.respond_to?(:chef_id) ? object.chef_id : object
        new(connection, data_bag).from_hash(connection.delete("#{data_bag.class.resource_path}/#{data_bag.name}/#{chef_id}").body)
      end

      # @param [Ridley::Connection] connection
      # @param [Ridley::DataBagResource] data_bag
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
      # @param [Ridley::DataBagResource] data_bag
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

    set_assignment_mode :carefree

    # @return [Ridley::DataBagResource]
    attr_reader :data_bag

    attribute :id,
      type: String,
      required: true

    # @param [Ridley::Connection] connection
    # @param [Ridley::DataBagResource] data_bag
    # @param [#to_hash] new_attrs
    def initialize(connection, data_bag, new_attrs = {})
      super(connection, new_attrs)
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

      mass_assign(self.class.create(connection, data_bag, self).attributes)
      true
    rescue Errors::HTTPConflict
      self.update
      true
    end

    # Decrypts this data bag item.
    #
    # @return [Hash] decrypted attributes
    def decrypt
      decrypted_hash = Hash[attributes.map { |key, value| [key, key == "id" ? value : decrypt_value(value)] }]
      mass_assign(decrypted_hash)
    end

    def decrypt_value(value)
      decoded_value = Base64.decode64(value)

      cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
      cipher.decrypt
      cipher.pkcs5_keyivgen(connection.encrypted_data_bag_secret)
      decrypted_value = cipher.update(decoded_value) + cipher.final

      YAML.load(decrypted_value)
    end

    # Reload the attributes of the instantiated resource
    #
    # @return [Object]
    def reload
      mass_assign(self.class.find(connection, data_bag, self).attributes)
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

      mass_assign(sself.class.update(connection, data_bag, self).attributes)
      true
    end

    # @param [#to_hash] hash
    #
    # @return [Object]
    def from_hash(hash)
      hash = HashWithIndifferentAccess.new(hash.to_hash)

      mass_assign(hash.has_key?(:raw_data) ? hash[:raw_data] : hash)
      self
    end

    def to_s
      self.attributes
    end

    private

      # @return [Ridley::Connection]
      attr_reader :connection
  end
end
