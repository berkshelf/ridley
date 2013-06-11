module Ridley
  module Mixin
    # A Ruby platform agnostic way of executing shell commands on the local system
    module ShellOut
      class Response
        # @return [Fixnum]
        attr_reader :exitstatus
        # @return [String]
        attr_reader :stdout
        # @return [String]
        attr_reader :stderr

        # @param [Fixnum] exitstatus
        # @param [String] stdout
        # @param [String] stderr
        def initialize(exitstatus, stdout, stderr)
          @exitstatus = exitstatus
          @stdout     = stdout
          @stderr     = stderr
        end

        def success?
          exitstatus == 0
        end

        def error?
          !success?
        end
        alias_method :failure?, :error?
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
            pid         = Process.spawn(command, out: out.to_i, err: err.to_i)
            pid, status = Process.waitpid2(pid)
            exitstatus  = status.exitstatus
          rescue Errno::ENOENT => ex
            exitstatus = 127
            out.write("")
            err.write("command not found: #{command}")
          end

          out.close
          err.close

          [ exitstatus, File.read(out), File.read(err) ]
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
