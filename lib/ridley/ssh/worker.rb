module Ridley
  class SSH
    # @author Jamie Winsor <reset@riotgames.com>
    # @api private
    class Worker
      include Celluloid
      include Celluloid::Logger

      attr_reader :sudo
      attr_reader :user
      # @return [Hashie::Mash]
      attr_reader :options
      
      # @param [Hash] options
      def initialize(options = {})
        @options = options.deep_symbolize_keys
        @sudo    = @options[:sudo]
        @user    = @options[:user]

        @options[:paranoid] = false
      end

      # @param [String] host
      # @param [String] command
      #
      # @return [Array]
      def run(host, command)
        response = Response.new(host)
        debug "Running SSH command: '#{command}' on: '#{host}' as: '#{user}'"

        Net::SSH.start(host, user, options.slice(*Net::SSH::VALID_OPTIONS)) do |ssh|
          ssh.open_channel do |channel|
            if self.sudo
              channel.request_pty
            end

            channel.exec(command) do |ch, success|
              unless success
                raise "FAILURE: could not execute command"
              end

              channel.on_data do |ch, data|
                response.stdout += data
                info "NODE[#{host}] #{data}" if data.present? and data != "\r\n"
              end

              channel.on_extended_data do |ch, type, data|
                response.stderr += data
                info "NODE[#{host}] #{data}" if data.present? and data != "\r\n"
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
          debug "Successfully ran SSH command on: '#{host}' as: '#{user}'"
          [ :ok, response ]
        else
          error "Successfully ran SSH command on: '#{host}' as: '#{user}', but it failed"
          error response.stdout
          [ :error, response ]
        end
      rescue => e
        error "Failed to run SSH command on: '#{host}' as: '#{user}'"
        error "#{e.class}: #{e.message}"
        response.exit_code = -1
        response.stderr = e.message
        [ :error, response ]
      end

      private

        attr_reader :runner
    end
  end
end
