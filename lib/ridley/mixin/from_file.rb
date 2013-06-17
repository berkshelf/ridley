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

      if File.exists?(filename) && File.readable?(filename)
        self.instance_eval(IO.read(filename), filename, 1)
        self
      else
        raise IOError, "Could not open or read: '#{filename}'"
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

      if File.exists?(filename) && File.readable?(filename)
        self.class_eval(IO.read(filename), filename, 1)
        self
      else
        raise IOError, "Could not open or read: '#{filename}'"
      end
    end
  end
end
