module Ridley::Mixin
  module FromFile
    module ClassMethods
      def from_file(filename, *args)
        new(*args).from_file(filename)
      end

      def class_from_file(filename, *args)
        new(*args).class_from_file(filename)
      end
    end

    class << self
      def included(base)
        base.extend(ClassMethods)
      end
    end

    # Loads the contents of a file within the context of the current object
    #
    # @param [#to_s] filename
    #   path to the file to load
    #
    # @raise [IOError] if the file does not exist or cannot be read
    def from_file(filename)
      filename = filename.to_s

      ensure_presence!(filename)

      with_error_handling(filename) do
        self.instance_eval(IO.read(filename), filename, 1)
        self
      end
    end

    # Loads the contents of a file within the context of the current object's class
    #
    # @param [#to_s] filename
    #   path to the file to load
    #
    # @raise [IOError] if the file does not exist or cannot be read
    def class_from_file(filename)
      filename = filename.to_s

      ensure_presence!(filename)

      with_error_handling(filename) do
        self.class_eval(IO.read(filename), filename, 1)
        self
      end
    end

    private

    # Ensure the given filename and path is readable
    #
    # @param [String] filename
    #
    # @raise [IOError]
    #   if the target file does not exist or is not readable
    def ensure_presence!(filename)
      unless File.exists?(filename) && File.readable?(filename)
        raise IOError, "Could not open or read: '#{filename}'"
      end
    end

    # Execute the given block, handling any exceptions that occur
    #
    # @param [String] filename
    #
    # @raise [Ridley::Errors::FromFileParserError]
    #   if any exceptions if raised
    def with_error_handling(filename)
      yield
    rescue => e
      raise Ridley::Errors::FromFileParserError.new(filename, e)
    end
  end
end
