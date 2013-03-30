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

        # @param  host [String]
        #   the host the worker is going to work on
        # @option options [Hash] :winrm
        #   * :user (String) a user that will login to each node and perform the bootstrap command on (required)
        #   * :password (String) the password for the user that will perform the bootstrap
        #   * :port (Fixnum) the winrm port to connect on the node the bootstrap will be performed on (5985)
        def initialize(host, options = {})
          @options        = options.deep_symbolize_keys
          @options        = options[:winrm] if options[:winrm]
          @host           = host
          @user           = @options[:user]
          @password       = @options[:password]
          @winrm_endpoint = "http://#{host}:#{winrm_port}/wsman"
        end

        def run(command)
          command = get_command(command)

          response = Ridley::HostConnector::Response.new(host)
          debug "Running WinRM Command: '#{command}' on: '#{host}' as: '#{user}'"

          output = winrm.run_cmd(command) do |stdout, stderr|
            response.stdout += stdout unless stdout.nil?
            response.stderr += stderr unless stderr.nil?
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

        # @return [::WinRM::WinRMWebService]
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
        def get_command(command)
          if command.length < 2047
            command
          else
            debug "Detected a command that was longer than 2047 characters, uploading command as a file to the host."
            upload_command_to_host(command)
          end
        end

        private

          # Uploads the command encoded as base64 to a file on the host
          # and then uses Powershell to transform the base64 file into the
          # command that was originally passed through.
          #
          # @param  command [String]
          #
          # @return [String] the command to execute the uploaded file
          def upload_command_to_host(command)
            base64_file = "winrm-upload-base64-#{Process.pid}-#{Time.now.to_i}"
            base64_file_name = get_file_path(base64_file)

            Base64.encode64(command).gsub("\n", '').chars.to_a.each_slice(8000 - base64_file_name.size) do |chunk|
              out = winrm.run_cmd( "echo #{chunk.join} >> \"#{base64_file_name}\"" )
            end

            command_file = "winrm-upload-#{Process.pid}-#{Time.now.to_i}.bat"
            command_file_name = get_file_path(command_file)
            winrm.powershell <<-POWERSHELL
              $base64_string = Get-Content \"#{base64_file_name}\"
              $bytes  = [System.Convert]::FromBase64String($base64_string) 
              $new_file = [System.IO.Path]::GetFullPath(\"#{command_file_name}\")
              [System.IO.File]::WriteAllBytes($new_file,$bytes)
            POWERSHELL

            "cmd.exe /C #{command_file_name}"
          end

          # @return [String]
          def get_file_path(file)
            (winrm.run_cmd("echo %TEMP%\\#{file}"))[:data][0][:stdout].chomp
          end
      end
    end
  end
end
