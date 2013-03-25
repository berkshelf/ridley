module Ridley
  module Connector
    class WinRM
      # @author Kyle Allan <kallan@riotgames.com>
      # @api private
      class Worker
        include Celluloid
        include Celluloid::Logger

        attr_reader :user
        attr_reader :options

        def initialize(options = {})
          @options = options.deep_symbolize_keys
          @user = @options[:user]
        end

        def run(host, command)
          response = Ridley::Connector::Response.new(host)
          debug "Running WinRM Command: '#{command}' on: '#{host}' as: '#{user}'"

          endpoint = "http://#{host}:#{Ridley::Connector::DEFAULT_WINRM_PORT}/wsman"
          winrm = ::WinRM::WinRMWebService.new(endpoint, :plaintext, :user => user, :pass => options[:pass], :basic_auth_only => true)
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
      end
    end
  end
end