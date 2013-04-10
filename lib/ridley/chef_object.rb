module Ridley
  class ChefObject
    include Chozo::VariaModel
    include Comparable

    # @param [Ridley::Resource] resource
    # @param [Hash] new_attrs
    def initialize(resource, new_attrs = {})
      @resource = resource
      mass_assign(new_attrs)
    end

    # Creates a resource on the target remote or updates one if the resource
    # already exists.
    #
    # @raise [Errors::InvalidResource]
    #   if the resource does not pass validations
    #
    # @return [Boolean]
    def save
      raise Errors::InvalidResource.new(self.errors) unless valid?

      mass_assign(resource.create(self)._attributes_)
      true
    rescue Errors::HTTPConflict
      self.update
      true
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

      mass_assign(resource.update(self)._attributes_)
      true
    end

    # Reload the attributes of the instantiated resource
    #
    # @return [Object]
    def reload
      mass_assign(resource.find(self)._attributes_)
      self
    end

    # @return [String]
    def chef_id
      get_attribute(resource.class.chef_id)
    end

    def inspect
      "#<#{self.class} chef_id:#{self.chef_id}, attributes:#{self._attributes_}>"
    end

    # @param [Object] other
    #
    # @return [Boolean]
    def <=>(other)
      self.chef_id <=> other.chef_id
    end

    def ==(other)
      self.chef_id == other.chef_id
    end

    # @param [Object] other
    #
    # @return [Boolean]
    def eql?(other)
      self.class == other.class && self == other
    end

    def hash
      self.chef_id.hash
    end

    private

      attr_reader :resource
  end
end
