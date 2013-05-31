require 'net/ssh'

module Ridley
  module HostConnector
    # @author Jamie Winsor <reset@riotgames.com>
    class SSH < HostConnector::Base
      EMBEDDED_RUBY_PATH = '/opt/chef/embedded/bin/ruby'.freeze

      def run(host, command, options = {})
        options = options.reverse_merge(paranoid: false, sudo: false)
        command = "sudo #{command}" if options[:sudo]

        log.info "Running SSH command: '#{command}' on: '#{host}' as: '#{options[:user]}'"

        Ridley::HostConnector::Response.new(host).tap do |response|
          channel_exec = ->(channel, command) do
            channel.exec(command) do |ch, success|
              unless success
                raise "Channel execution failed while executing command #{command}"
              end

              channel.on_data do |ch, data|
                response.stdout += data
                log.info "[#{host}](SSH) #{data}" if data.present? and data != "\r\n"
              end

              channel.on_extended_data do |ch, type, data|
                response.stderr += data
                log.info "[#{host}](SSH) #{data}" if data.present? and data != "\r\n"
              end

              channel.on_request("exit-status") do |ch, data|
                response.exit_code = data.read_long
              end

              channel.on_request("exit-signal") do |ch, data|
                response.exit_signal = data.read_string
              end
            end
          end

          begin
            Net::SSH.start(host, options[:user], options.slice(*Net::SSH::VALID_OPTIONS)) do |ssh|
              ssh.open_channel do |channel|
                if options[:sudo]
                  channel.request_pty do |channel, success|
                    unless success
                      raise "Could not aquire pty: A pty is required for running sudo commands."
                    end

                    channel_exec.call(channel, command)
                  end
                else
                  channel_exec.call(channel, command)
                end
              end
              ssh.loop
            end
          rescue Net::SSH::Exception => ex
            response.exit_code = -1
            response.stderr    = ex.message
            return [ :error, response ]
          end

          case response.exit_code
          when 0
            log.info "Successfully ran SSH command on: '#{host}' as: '#{options[:user]}'"
            [ :ok, response ]
          else
            log.info "Successfully ran SSH command on: '#{host}' as: '#{options[:user]}' but it failed"
            [ :error, response ]
          end
        end
      end

      # Executes a chef-client command on the nodes
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
        cmd = "echo '#{secret}' > /etc/chef/encrypted_data_bag_secret; chmod 0600 /etc/chef/encrypted_data_bag_secret"
        run(host, cmd, options)
      end

      # Executes a provided Ruby script in the embedded Ruby installation
      #
      # @param [Array<String>] command_lines
      #   An Array of lines of the command to be executed
      #
      # @return [#run]
      def ruby_script(host, command_lines, options = {})
        run(host, "#{EMBEDDED_RUBY_PATH} -e \"#{command_lines.join(';')}\"", options)
      end
    end
  end
end
