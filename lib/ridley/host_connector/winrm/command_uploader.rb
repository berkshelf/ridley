module Ridley
  module HostConnector
    class WinRM
      # @author Kyle Allan <kallan@riotgames.com>
      # @author Justin Campbell <justin.campbell@riotgames.com>
      class CommandUploader
        
        CHUNK_LIMIT = 1024

        attr_reader :command_string
        attr_reader :winrm

        # @param [String] command_string
        # @param [WinRM::WinRMWebService] winrm
        def initialize(command_string, winrm)
          @command_string = command_string
          @winrm          = winrm
        end

        # Uploads the command encoded as base64 to a file on the host
        # and then uses Powershell to transform the base64 file into the
        # command that was originally passed through.
        def upload
          upload_command
          convert_command
        end

        # @return [String] the command to execute the uploaded file
        def command
          "cmd.exe /C #{command_file_name}"
        end

        private

          def upload_command
            command_string_chars.each_slice(CHUNK_LIMIT) do |chunk|
              winrm.run_cmd( "echo #{chunk.join} >> \"#{base64_file_name}\"" )
            end
          end

          def command_string_chars
            Base64.encode64(command_string).gsub("\n", '').chars.to_a
          end

          def convert_command
            winrm.powershell <<-POWERSHELL
              $base64_string = Get-Content \"#{base64_file_name}\"
              $bytes  = [System.Convert]::FromBase64String($base64_string) 
              $new_file = [System.IO.Path]::GetFullPath(\"#{command_file_name}\")
              [System.IO.File]::WriteAllBytes($new_file,$bytes)
            POWERSHELL
          end

          def base64_file_name
            @base64_file_name ||= get_file_path("winrm-upload-base64-#{unique_string}")
          end

          def command_file_name
            @command_file_name ||= get_file_path("winrm-upload-#{unique_string}.bat")
          end

          def unique_string
            @unique_string ||= "#{Process.pid}-#{Time.now.to_i}"
          end

          # @return [String]
          def get_file_path(file)
            (winrm.run_cmd("echo %TEMP%\\#{file}"))[:data][0][:stdout].chomp
          end
      end
    end
  end
end