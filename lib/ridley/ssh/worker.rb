module Ridley
  class SSH
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class Worker
      include Celluloid
      include Celluloid::Logger

      # @param [Ridley::SSH] runner
      # @param [String] host
      # @param [Hash] options
      def initialize(runner, host, options = {})
        @runner  = runner
        @options = options
        @host    = host
        @user    = options.fetch(:user)
      end

      # @param [String] command
      #
      # @return [Array]
      def run(command)
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

        debug "Ran SSH command: '#{command}' successful on: '#{host}' as: '#{user}'"

        runner.mailbox << case response.exit_code
        when 0
          [ :ok, response ]
        else
          [ :error, response ]
        end
      rescue => e
        runner.mailbox << [ :error, e.message ]
      end

      private

        attr_reader :runner
        attr_reader :host
        attr_reader :user
        attr_reader :options
    end
  end
end
