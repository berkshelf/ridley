require 'erubis'

module Ridley
  module CommandContext
    # A base class to provide common functionality between OS specific command contexts. A
    # command context takes an options hash and binds it against a template file. You can then
    # retrieve the command to be run on a node by calling {CommandContext::Base#command}.
    #
    # @example
    #   my_context = MyCommandContext.new(message: "hello, world!")
    #   my_context.command #=> "echo 'hello, world!'"
    class Base
      class << self
        # Build a command context and immediately run it's command
        #
        # @param [Hash] options
        #   an options hash to pass to the new CommandContext
        def command(options = {})
          new(options).command
        end

        # Set or get the path to the template file for the inheriting class
        #
        # @param [String] filename
        #   the filename (without extension) of the template file to use to bind
        #   the inheriting command context class to
        #
        # @return [Pathname]
        def template_file(filename = nil)
          return @template_file if filename.nil?
          @template_file = Ridley.scripts.join("#{filename}.erb")
        end
      end

      # @param [Hash] options
      def initialize(options = {}); end

      # @return [String]
      def command
        template.evaluate(self)
      end

      private

        # @return [Erubis::Eruby]
        def template
          @template ||= Erubis::Eruby.new(IO.read(self.class.template_file).chomp)
        end
    end

    # A command context for Unix based OSes
    class Unix < Base
      # @return [Boolean]
      attr_reader :sudo

      # @option options [Boolean] :sudo (true)
      #   bootstrap with sudo (default: true)
      def initialize(options = {})
        options = options.reverse_merge(sudo: true)
        @sudo   = options[:sudo]
      end

      # @return [String]
      def command
        sudo ? "sudo #{super}" : super
      end
    end

    # A command context for Windows based OSes
    class Windows < Base; end
  end
end

Dir["#{File.dirname(__FILE__)}/command_context/*.rb"].sort.each do |path|
  require_relative "command_context/#{File.basename(path, '.rb')}"
end
