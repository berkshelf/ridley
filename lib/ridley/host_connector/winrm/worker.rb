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

        def initialize(host, options = {})
          @options        = options.deep_symbolize_keys
          @options        = options[:winrm] if options[:winrm]
          @host           = host
          @user           = @options[:user]
          @password       = @options[:password]
          @winrm_endpoint = "http://#{host}:#{winrm_port}/wsman"
        end

        def run(command)
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

        def winrm
          ::WinRM::WinRMWebService.new(winrm_endpoint, :plaintext, user: user, pass: password, basic_auth_only: true)
        end

        def winrm_port
          options[:port] || Ridley::HostConnector::DEFAULT_WINRM_PORT
        end
      end
    end
  end
end
