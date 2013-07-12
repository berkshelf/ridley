# Silencing warnings because not all versions of GSSAPI support all of the GSSAPI methods
# the gssapi gem attempts to attach to and these warnings are dumped to STDERR.
silence_warnings do
  require 'winrm'
end

module Ridley
  module HostConnector
    class WinRM < HostConnector::Base
      require_relative 'winrm/command_uploader'

      DEFAULT_PORT                 = 5985
      EMBEDDED_RUBY_PATH           = 'C:\opscode\chef\embedded\bin\ruby'.freeze
      SESSION_TYPE_COMMAND_METHODS = {
        powershell: :run_powershell_script,
        cmd: :run_cmd
      }.freeze

      # Execute a shell command on a node
      #
      # @param [String] host
      #   the host to perform the action on
      # @param [String] command
      #
      # @option options [Symbol] :session_type (:cmd)
      #   * :powershell - run the given command in a powershell session
      #   * :cmd - run the given command in a cmd session
      # @option options [Hash] :winrm
      #   * :user (String) a user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the user that will perform the bootstrap (required)
      #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
      #
      # @return [HostConnector::Response]
      def run(host, command, options = {})
        options = options.reverse_merge(winrm: Hash.new, session_type: :cmd)
        options[:winrm].reverse_merge!(port: DEFAULT_PORT)

        command_uploaders = Array.new
        user              = options[:winrm][:user]
        password          = options[:winrm][:password]
        port              = options[:winrm][:port]
        connection        = winrm(host, port, options[:winrm].slice(:user, :password))

        unless command_method = SESSION_TYPE_COMMAND_METHODS[options[:session_type]]
          raise RuntimeError, "unknown session type: #{options[:session_type]}. Known session types " +
            "are: #{SESSION_TYPE_COMMAND_METHODS.keys}"
        end

        HostConnector::Response.new(host).tap do |response|
          begin
            command_uploaders << command_uploader = CommandUploader.new(connection)
            command = get_command(command, command_uploader)

            log.info "Running WinRM Command: '#{command}' on: '#{host}' as: '#{user}'"

            defer {
              output = connection.send(command_method, command) do |stdout, stderr|
                if stdout && stdout.present?
                  response.stdout += stdout
                  log.info "[#{host}](WinRM) #{stdout}"
                end

                if stderr && stderr.present?
                  response.stderr += stderr
                  log.info "[#{host}](WinRM) #{stderr}"
                end
              end
              response.exit_code = output[:exitcode]
            }
          rescue ::WinRM::WinRMHTTPTransportError => ex
            response.exit_code = :transport_error
            response.stderr    = ex.message
          end

          case response.exit_code
          when 0
            log.info "Successfully ran WinRM command on: '#{host}' as: '#{user}'"
          when :transport_error
            log.info "A transport error occured while attempting to run a WinRM command on: '#{host}' as: '#{user}'"
          else
            log.info "Successfully ran WinRM command on: '#{host}' as: '#{user}', but it failed"
          end
        end
      ensure
        begin
          command_uploaders.map(&:cleanup)
        rescue ::WinRM::WinRMHTTPTransportError => ex
          log.info "Error cleaning up leftover Powershell scripts on some hosts"
        end
      end

      # Returns the command if it does not break the WinRM command length
      # limit. Otherwise, we return an execution of the command as a batch file.
      #
      # @param  command [String]
      #
      # @return [String]
      def get_command(command, command_uploader)
        if command.length < CommandUploader::CHUNK_LIMIT
          command
        else
          log.debug "Detected a command that was longer than #{CommandUploader::CHUNK_LIMIT} characters. " +
            "Uploading command as a file to the host."
          command_uploader.upload(command)
          command_uploader.command
        end
      end

      # Bootstrap a node
      #
      # @param [String] host
      #   the host to perform the action on
      #
      # @option options [Hash] :winrm
      #   * :user (String) a user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the user that will perform the bootstrap (required)
      #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
      #
      # @return [HostConnector::Response]
      def bootstrap(host, options = {})
        context = BootstrapContext::Windows.new(options)

        log.info "Bootstrapping host: #{host}"
        run(host, context.boot_command, options)
      end

      # Perform a chef client run on a node
      #
      # @param [String] host
      #   the host to perform the action on
      #
      # @option options [Hash] :winrm
      #   * :user (String) a user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the user that will perform the bootstrap (required)
      #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
      #
      # @return [HostConnector::Response]
      def chef_client(host, options = {})
        run(host, "chef-client", options)
      end

      # Write your encrypted data bag secret on a node
      #
      # @param [String] host
      #   the host to perform the action on
      # @param [String] secret
      #   your organization's encrypted data bag secret
      #
      # @option options [Hash] :winrm
      #   * :user (String) a user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the user that will perform the bootstrap (required)
      #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
      #
      # @return [HostConnector::Response]
      def put_secret(host, secret, options = {})
        command = "echo #{secret} > C:\\chef\\encrypted_data_bag_secret"
        run(host, command, options)
      end

      # Execute line(s) of Ruby code on a node using Chef's embedded Ruby
      #
      # @param [String] host
      #   the host to perform the action on
      # @param [Array<String>] command_lines
      #   An Array of lines of the command to be executed
      #
      # @option options [Hash] :winrm
      #   * :user (String) a user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the user that will perform the bootstrap (required)
      #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
      #
      # @return [HostConnector::Response]
      def ruby_script(host, command_lines, options = {})
        command = "#{EMBEDDED_RUBY_PATH} -e \"#{command_lines.join(';')}\""
        run(host, command, options)
      end

      # Uninstall Chef from a node
      #
      # @param [String] host
      #   the host to perform the action on
      #
      # @option options [Boolena] :skip_chef (false)
      #   skip removal of the Chef package and the contents of the installation
      #   directory. Setting this to true will only remove any data and configurations
      #   generated by running Chef client.
      # @option options [Hash] :winrm
      #   * :user (String) a user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the user that will perform the bootstrap (required)
      #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
      #
      # @return [HostConnector::Response]
      def uninstall_chef(host, options = {})
        options[:session_type] = :powershell
        log.info "Uninstalling Chef from host: #{host}"
        run(host, CommandContext::WindowsUninstall.command(options), options)
      end

      private

        # @param [String] host
        # @param [Integer] port
        #
        # @option options [String] :user
        # @option options [String] :password
        #
        # @return [WinRM::WinRMWebService]
        def winrm(host, port, options = {})
          winrm_opts = { disable_sspi: true, basic_auth_only: true }
          winrm_opts[:user] = options[:user]
          winrm_opts[:pass] = options[:password]
          client = ::WinRM::WinRMWebService.new("http://#{host}:#{port}/wsman", :plaintext, winrm_opts)
          client.set_timeout(6000)
          client
        end
    end
  end
end
