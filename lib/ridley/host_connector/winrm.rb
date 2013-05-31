require 'active_support/core_ext/kernel/reporting'
# Silencing warnings because not all versions of GSSAPI support all of the GSSAPI methods
# the gssapi gem attempts to attach to and these warnings are dumped to STDERR.
silence_warnings do
  require 'winrm'
end

module Ridley
  module HostConnector
    # @author Kyle Allan <kallan@riotgames.com>
    class WinRM < HostConnector::Base
      require_relative 'winrm/command_uploader'

      DEFAULT_PORT       = 5985
      EMBEDDED_RUBY_PATH = 'C:\opscode\chef\embedded\bin\ruby'.freeze

      # @option options [String] :user
      #   a user that will login to each node and perform the bootstrap command on (required)
      # @option options [String] :password
      #   the password for the user that will perform the bootstrap (required)
      # @option options [Fixnum] :port (5985)
      #   the winrm port to connect on the node the bootstrap will be performed on
      def run(host, command, options = {})
        command_uploaders = Array.new
        user              = options[:user]
        password          = options[:password]
        port              = options[:port] || DEFAULT_PORT
        connection        = winrm(host, port, options.slice(:user, :password))

        HostConnector::Response.new(host).tap do |response|
          command_uploaders << command_uploader = CommandUploader.new(connection)
          command = get_command(command, command_uploader)

          begin
            log.info "Running WinRM Command: '#{command}' on: '#{host}' as: '#{user}'"

            output = connection.run_cmd(command) do |stdout, stderr|
              if stdout
                response.stdout += stdout
                log.info "[#{host}](WinRM) #{stdout}"
              end

              if stderr
                response.stderr += stderr unless stderr.nil?
                log.info "[#{host}](WinRM) #{stdout}"
              end
            end

            response.exit_code = output[:exitcode]
          rescue ::WinRM::WinRMHTTPTransportError => ex
            response.exit_code = -1
            response.stderr    = ex.message
            return response
          end

          case response.exit_code
          when 0
            log.info "Successfully ran WinRM command on: '#{host}' as: '#{user}'"
          else
            log.info "Successfully ran WinRM command on: '#{host}' as: '#{user}', but it failed"
          end
        end
      ensure
        command_uploaders.map(&:cleanup)
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
          log.debug "Detected a command that was longer than #{CommandUploader::CHUNK_LIMIT} characters, \
            uploading command as a file to the host."
          command_uploader.upload(command)
          command_uploader.command
        end
      end

      def bootstrap(host, options = {})
        context = BootstrapContext::Windows.new(options)

        log.info "Bootstrapping host: #{host}"
        run(context.boot_command, options)
      end

      # Executes a chef-client run on the nodes
      #
      # @return [#run]
      def chef_client(host, options = {})
        run(host, "chef-client", options)
      end

      # Writes the given encrypted data bag secret to the node
      #
      # @param [String] secret
      #   your organization's encrypted data bag secret
      #
      # @return [#run]
      def put_secret(host, secret, options = {})
        command = "echo #{secret} > C:\\chef\\encrypted_data_bag_secret"
        run(host, command, options)
      end

      # Executes a provided Ruby script in the embedded Ruby installation
      #
      # @param [Array<String>] command_lines
      #   An Array of lines of the command to be executed
      #
      # @return [#run]
      def ruby_script(host, command_lines, options = {})
        command = "#{EMBEDDED_RUBY_PATH} -e \"#{command_lines.join(';')}\""
        run(host, command, options)
      end

      private

        # @return [WinRM::WinRMWebService]
        def winrm(host, port, options = {})
          options = options.merge(disable_sspi: true, basic_auth_only: true)
          client = ::WinRM::WinRMWebService.new("http://#{host}:#{port}/wsman", :plaintext, options)
          client.set_timeout(6000)
          client
        end
    end
  end
end
