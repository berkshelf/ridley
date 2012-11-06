module Ridley
  class SSH
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class Worker
      include Celluloid
      include Celluloid::Logger
      
      # @param [Hash] options
      def initialize(options = {})
        @options = options
        @user    = options.fetch(:user)
      end

      # @param [String] host
      # @param [String] command
      #
      # @return [Array]
      def run(host, command)
        response = Response.new("", "")
        debug "Running SSH command: '#{command}' on: '#{host}' as: '#{user}'"

        Net::SSH.start(host, user, options) do |ssh|          
          ssh.open_channel do |channel|
            channel.exec(command) do |ch, success|
              unless success
                raise "FAILURE: could not execute command"
              end

              channel.on_data do |ch, data|
                response.stdout += data
              end

              channel.on_extended_data do |ch, type, data|
                response.stderr += data
              end

              channel.on_request("exit-status") do |ch, data|
                response.exit_code = data.read_long
              end

              channel.on_request("exit-signal") do |ch, data|
                response.exit_signal = data.read_string
              end
            end
          end

          ssh.loop
        end

        case response.exit_code
        when 0
          debug "Successfully ran SSH command: '#{command}' on: '#{host}' as: '#{user}' and it succeeded"
          [ :ok, response ]
        else
          debug "Successfully ran SSH command: '#{command}' on: '#{host}' as: '#{user}' but it failed"
          [ :error, response ]
        end
      rescue => e
        debug "Failed to run SSH command: '#{command}' on: '#{host}' as: '#{user}'"
        [ :error, e.message ]
      end

      private

        attr_reader :runner
        attr_reader :user
        attr_reader :options
    end
  end
end
