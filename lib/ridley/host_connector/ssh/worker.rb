module Ridley
  module HostConnector
    class SSH
      # @author Jamie Winsor <reset@riotgames.com>
      # @api private
      class Worker
        include Celluloid
        include Celluloid::Logger

        attr_reader :sudo
        attr_reader :user
        attr_reader :host
        # @return [Hashie::Mash]
        attr_reader :options

        EMBEDDED_RUBY_PATH = '/opt/chef/embedded/bin/ruby'.freeze

        # @param [Hash] options
        def initialize(host, options = {})
          options = options.deep_symbolize_keys
          @options = options[:ssh] || Hash.new
          @host    = host
          @sudo    = @options[:sudo]
          @user    = @options[:user]

          @options[:paranoid] = false
        end

        # @param [String] command
        #
        # @return [Array]
        def run(command)
          response = Ridley::HostConnector::Response.new(host)
          debug "Running SSH command: '#{command}' on: '#{host}' as: '#{user}'"

          channel_exec = ->(channel, command) do
            channel.exec(command) do |ch, success|
              unless success
                raise "Channel execution failed while executing command #{command}"
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

          Net::SSH.start(host, user, options.slice(*Net::SSH::VALID_OPTIONS)) do |ssh|
            ssh.open_channel do |channel|
              if self.sudo
                channel.request_pty do |channel, success|
                  raise "Could not aquire pty: A pty is required for running sudo commands." unless success

                  channel_exec.call(channel, command)
                end
              else
                channel_exec.call(channel, command)
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

        # Executes a chef-client command on the nodes
        #
        # @return [#run]
        def chef_client
          command = "chef-client"
          if sudo
            command = "sudo #{command}"
          end

          run(command)
        end

        # Writes the given encrypted data bag secret to the node
        #
        # @param [String] secret
        #   your organization's encrypted data bag secret
        #
        # @return [#run]
        def put_secret(secret)
          command = "echo '#{secret}' > /etc/chef/encrypted_data_bag_secret; chmod 0600 /etc/chef/encrypted_data_bag_secret"
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

        private

          attr_reader :runner
      end
    end
  end
end
