module Ridley
  module Mixin
    # A Ruby platform agnostic way of executing shell commands on the local system
    module ShellOut
      class Response
        extend Forwardable

        # @return [String]
        attr_reader :stdout
        # @return [String]
        attr_reader :stderr

        def_delegator :process_status, :exitstatus
        def_delegator :process_status, :pid
        def_delegator :process_status, :success?
        def_delegator :process_status, :exited?
        def_delegator :process_status, :stopped?

        # @param [Process::Status] process_status
        # @param [String] stdout
        # @param [String] stderr
        def initialize(process_status, stdout, stderr)
          @process_status = process_status
          @stdout         = stdout
          @stderr         = stderr
        end

        def error?
          !success?
        end
        alias_method :failure?, :error?

        private

          # @return [Process::Status]
          attr_reader :process_status
      end

      include Chozo::RubyEngine
      extend self

      # Executes the given shell command on the local system
      #
      # @param [String] command
      #   The command to execute
      #
      # @return [ShellOut::Response]
      def shell_out(command)
        process_status, out, err = jruby? ? jruby_out(command) : mri_out(command)
        Response.new(process_status, out, err)
      end

      private

        # @param [String] command
        #   The command to execute
        def mri_out(command)
          out, err = Tempfile.new('ridley.shell_out.stdout'), Tempfile.new('ridley.shell_out.stderr')

          begin
            pid = Process.spawn(command, out: out.to_i, err: err.to_i)
            Process.waitpid(pid)
          rescue Errno::ENOENT
            out.write("")
            err.write("command not found: #{command}")
          end

          out.close
          err.close

          [ $?, File.read(out), File.read(err) ]
        end

        # @param [String] command
        #   The command to execute
        def jruby_out(command)
          out, err = StringIO.new, StringIO.new
          $stdout, $stderr = out, err
          system(command)

          out.rewind
          err.rewind
          [ $?, out.read, err.read ]
        ensure
          $stdout, $stderr = STDOUT, STDERR
        end
    end
  end
end
