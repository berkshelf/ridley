module Ridley
  module HostConnector
    class WinRM
      # @author Kyle Allan <kallan@riotgames.com>
      # @api private
      class Worker
        include Celluloid
        include Celluloid::Logger

        # @return [String]
        attr_reader :user
        # @return [String]
        attr_reader :password
        # @return [String]
        attr_reader :host
        # @return [Hash]
        attr_reader :options
        # @return [String]
        attr_reader :winrm_endpoint
        # @return [CommandUploader]
        attr_reader :command_uploader
        # @return [Array]
        attr_reader :command_uploaders

        finalizer :finalizer

        EMBEDDED_RUBY_PATH = 'C:\opscode\chef\embedded\bin\ruby'.freeze

        # @param  host [String]
        #   the host the worker is going to work on
        # @option options [Hash] :winrm
        #   * :user (String) a user that will login to each node and perform the bootstrap command on (required)
        #   * :password (String) the password for the user that will perform the bootstrap
        #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
        def initialize(host, options = {})
          options            = options.deep_symbolize_keys
          @options           = options[:winrm] || Hash.new
          @host              = host
          @user              = @options[:user]
          @password          = @options[:password]
          @winrm_endpoint    = "http://#{host}:#{winrm_port}/wsman"
          @command_uploaders = Array.new
        end

        def finalizer
          command_uploaders.map(&:cleanup)
        end

        def run(command)
          command_uploaders << command_uploader = CommandUploader.new(winrm)
          command = get_command(command, command_uploader)

          response = Ridley::HostConnector::Response.new(host)
          debug "Running WinRM Command: '#{command}' on: '#{host}' as: '#{user}'"

          output = winrm.run_cmd(command) do |stdout, stderr|
            if stdout
              response.stdout += stdout
              info "NODE[#{host}] #{stdout}"
            end

            if stderr
              response.stderr += stderr unless stderr.nil?
              info "NODE[#{host}] #{stdout}"
            end
          end

          response.exit_code = output[:exitcode]

          case response.exit_code
          when 0
            debug "Successfully ran WinRM command on: '#{host}' as: '#{user}'"
            [ :ok, response ]
          else
            error "Successfully ran WinRM command on: '#{host}' as: '#{user}', but it failed"
            error response.stdout
            [ :error, response ]
          end
        rescue => e
          error "Failed to run WinRM command on: '#{host}' as: '#{user}'"
          error "#{e.class}: #{e.message}"
          response.exit_code = -1
          response.stderr = e.message
          [ :error, response ]
        end

        # @return [WinRM::WinRMWebService]
        def winrm
          ::WinRM::WinRMWebService.new(winrm_endpoint, :plaintext, user: user, pass: password, disable_sspi: true, basic_auth_only: true)
        end

        # @return [Fixnum]
        def winrm_port
          options[:port] || Ridley::HostConnector::DEFAULT_WINRM_PORT
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
            debug "Detected a command that was longer than #{CommandUploader::CHUNK_LIMIT} characters, \
              uploading command as a file to the host."
            command_uploader.upload(command)
            command_uploader.command
          end
        end

        # Executes a chef-client run on the nodes
        #
        # @return [#run]
        def chef_client
          run("chef-client")
        end

        # Writes the given encrypted data bag secret to the node
        #
        # @param [String] secret
        #   your organization's encrypted data bag secret
        #
        # @return [#run]
        def put_secret(secret)
          command = "echo #{secret} > C:\\chef\\encrypted_data_bag_secret"
          run(command)
        end

        # Executes a provided Ruby script in the embedded Ruby installation
        #
        # @param [Array<String>] command_lines
        #   An Array of lines of the command to be executed
        #
        # @return [#run]
        def ruby_script(command_lines)
          command = "#{EMBEDDED_RUBY_PATH} -e \"#{command_lines.join(';')}\""
          run(command)
        end
      end
    end
  end
end
