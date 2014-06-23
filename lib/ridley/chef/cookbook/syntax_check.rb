require 'erubis'

module Ridley::Chef
  class Cookbook
    # Encapsulates the process of validating the ruby syntax of files in Chef
    # cookbooks.
    #
    # Borrowed and modified from: {https://github.com/opscode/chef/blob/11.4.0/lib/chef/cookbook/syntax_check.rb}
    #
    # Copyright:: Copyright (c) 2010 Opscode, Inc.
    #
    # Licensed under the Apache License, Version 2.0 (the "License");
    # you may not use this file except in compliance with the License.
    # You may obtain a copy of the License at
    #
    #     http://www.apache.org/licenses/LICENSE-2.0
    #
    # Unless required by applicable law or agreed to in writing, software
    # distributed under the License is distributed on an "AS IS" BASIS,
    # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    # See the License for the specific language governing permissions and
    # limitations under the License.
    class SyntaxCheck
      # Implements set behavior with disk-based persistence. Objects in the set
      # are expected to be strings containing only characters that are valid in
      # filenames.
      #
      # This class is used to track which files have been syntax checked so
      # that known good files are not rechecked.
      class PersistentSet
        attr_reader :cache_path

        # Create a new PersistentSet. Values in the set are persisted by
        # creating a file in the +cache_path+ directory. If not given, the
        # value of Chef::Config[:syntax_check_cache_path] is used; if that
        # value is not configured, the value of
        # Chef::Config[:cache_options][:path] is used.
        #--
        # history: prior to Chef 11, the cache implementation was based on
        # moneta and configured via cache_options[:path]. Knife configs
        # generated with Chef 11 will have `syntax_check_cache_path`, but older
        # configs will have `cache_options[:path]`. `cache_options` is marked
        # deprecated in chef/config.rb but doesn't currently trigger a warning.
        # See also: CHEF-3715
        def initialize(cache_path = nil)
          @cache_path = cache_path || Dir.mktmpdir
          @cache_path_created = false
        end

        # Adds +value+ to the set's collection.
        def add(value)
          ensure_cache_path_created
          FileUtils.touch(File.join(cache_path, value))
        end

        # Returns true if the set includes +value+
        def include?(value)
          File.exist?(File.join(cache_path, value))
        end

        private

          def ensure_cache_path_created
            return true if @cache_path_created
            FileUtils.mkdir_p(cache_path)
            @cache_path_created = true
          end
      end

      include Ridley::Logging
      include Ridley::Mixin::Checksum

      attr_reader :cookbook_path

      # A PersistentSet object that tracks which files have already been
      # validated.
      attr_reader :validated_files

      # Create a new SyntaxCheck object
      #
      # @param [String] cookbook_path
      #   the (on disk) path to the cookbook
      # @param [Ridley::Chef::Chefignore] chefignore
      #   the instance of R::C::Chefignore to filter out
      def initialize(cookbook_path, chefignore = nil)
        @cookbook_path   = cookbook_path
        @validated_files = PersistentSet.new
        @chefignore      = chefignore
      end


      def ruby_files
        Dir[File.join(cookbook_path, '**', '*.rb')].reject { |f| ignored?(f) }
      end

      def untested_ruby_files
        ruby_files.reject { |file| validated?(file) }
      end

      def template_files
        Dir[File.join(cookbook_path, '**', '*.erb')].reject { |f| ignored?(f) }
      end

      def untested_template_files
        template_files.reject { |file| validated?(file) }
      end

      def validated?(file)
        validated_files.include?(checksum(file))
      end

      def validated(file)
        validated_files.add(checksum(file))
      end

      def validate_ruby_files
        untested_ruby_files.each do |ruby_file|
          return false unless validate_ruby_file(ruby_file)
          validated(ruby_file)
        end
        true
      end

      def validate_templates
        untested_template_files.each do |template|
          return false unless validate_template(template)
          validated(template)
        end
        true
      end

      # Borrowed from: https://github.com/opscode/chef/blob/d111e82/lib/chef/cookbook/syntax_check.rb#L191-L215
      def validate_template(erb_file)
        old_stderr = $stderr

        engine = Erubis::Eruby.new
        engine.convert!(IO.read(erb_file))

        ruby_code = engine.src

        # Even when we're compiling the code w/ RubyVM, syntax errors just
        # print to $stderr. We want to capture this and handle the printing
        # ourselves, so we must temporarily swap $stderr to capture the output.
        tmp_stderr = $stderr = StringIO.new

        abs_path = File.expand_path(erb_file)
        RubyVM::InstructionSequence.new(ruby_code, erb_file, abs_path, 0)

        true
      rescue SyntaxError
        $stderr = old_stderr
        invalid_erb_file(erb_file, tmp_stderr.string)
        false
      ensure
        $stderr = old_stderr if defined?(old_stderr) && old_stderr
      end

      # Borrowed from: https://github.com/opscode/chef/blob/d111e82/lib/chef/cookbook/syntax_check.rb#L242-L264
      def validate_ruby_file(ruby_file)
        # Even when we're compiling the code w/ RubyVM, syntax errors just
        # print to $stderr. We want to capture this and handle the printing
        # ourselves, so we must temporarily swap $stderr to capture the output.
        old_stderr = $stderr
        tmp_stderr = $stderr = StringIO.new
        abs_path = File.expand_path(ruby_file)
        file_content = IO.read(abs_path)

        # We have to wrap this in a block so the user code evaluates in a
        # similar context as what Chef does normally. Otherwise RubyVM
        # will reject some common idioms, like using `return` to end evaluation
        # of a recipe. See also CHEF-5199
        wrapped_content = "Object.new.instance_eval do\n#{file_content}\nend\n"
        RubyVM::InstructionSequence.new(wrapped_content, ruby_file, abs_path, 0)
        true
      rescue SyntaxError
        $stderr = old_stderr
        invalid_ruby_file(ruby_file, tmp_stderr.string)
        false
      ensure
        $stderr = old_stderr if defined?(old_stderr) && old_stderr
      end

      private

        # @return [Ridley::Chef::Chefignore, nil]
        attr_reader :chefignore

        def ignored?(file)
          !!chefignore && chefignore.ignored?(file)
        end

        # Debug a syntax error in a template.
        def invalid_erb_file(erb_file, error_message)
          log.error("Erb template #{erb_file} has a syntax error:")
          error_message.each_line { |l| log.error(l.chomp) }
          nil
        end

        # Debugs ruby syntax errors by printing the path to the file and any
        # diagnostic info given in +error_message+
        def invalid_ruby_file(ruby_file, error_message)
          log.error("Cookbook file #{ruby_file} has a ruby syntax error:")
          error_message.each_line { |l| log.error(l.chomp) }
          false
        end
    end
  end
end
