require 'buff/ignore'

module Ridley::Chef
  class Chefignore < Buff::Ignore::IgnoreFile
    include Ridley::Logging

    # The filename of the chefignore
    #
    # @return [String]
    FILENAME = 'chefignore'.freeze

    # Create a new chefignore
    #
    # @param [#to_s] path
    #   the path to find a chefignore from (default: `Dir.pwd`)
    def initialize(path = Dir.pwd)
      ignore = chefignore(path)

      if ignore
        log.debug "Using '#{FILENAME}' at '#{ignore}'"
      end

      super(ignore, base: path)
    end

    private

      # Find the chefignore file in the current directory
      #
      # @return [String, nil]
      #   the path to the chefignore file or nil if one was not
      #   found
      def chefignore(path)
        Pathname.new(path).ascend do |dir|
          next unless dir.directory?

          [
            dir.join(FILENAME),
            dir.join('cookbooks', FILENAME),
            dir.join('.chef',     FILENAME),
          ].each do |possible|
            return possible.expand_path.to_s if possible.exist?
          end
        end

        nil
      end
  end
end
