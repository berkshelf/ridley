require 'net/ssh'

module Ridley
  module HostConnector
    class SSH < HostConnector::Base
      DEFAULT_PORT       = 22
      EMBEDDED_RUBY_PATH = '/opt/chef/embedded/bin/ruby'.freeze

      # Execute a shell command on a node
      #
      # @param [String] host
      #   the host to perform the action on
      # @param [String] command
      #
      # @option options [Hash] :ssh
      #   * :user (String) a shell user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the shell user that will perform the bootstrap
      #   * :keys (Array, String) an array of key(s) to authenticate the ssh user with instead of a password
      #   * :timeout (Float) timeout value for SSH bootstrap (5.0)
      #   * :sudo (Boolean) run as sudo
      #
      # @return [HostConnector::Response]
      def run(host, command, options = {})
        options = options.reverse_merge(ssh: Hash.new)
        options[:ssh].reverse_merge!(port: DEFAULT_PORT, paranoid: false, sudo: false)

        command = "sudo #{command}" if options[:ssh][:sudo]

        Ridley::HostConnector::Response.new(host).tap do |response|
          begin
            log.info "Running SSH command: '#{command}' on: '#{host}' as: '#{options[:ssh][:user]}'"

            defer {
              Net::SSH.start(host, options[:ssh][:user], options[:ssh].slice(*Net::SSH::VALID_OPTIONS)) do |ssh|
                ssh.open_channel do |channel|
                  if options[:sudo]
                    channel.request_pty do |channel, success|
                      unless success
                        raise "Could not aquire pty: A pty is required for running sudo commands."
                      end

                      channel_exec(channel, command, host, response)
                    end
                  else
                    channel_exec(channel, command, host, response)
                  end
                end
                ssh.loop
              end
            }
          rescue Net::SSH::AuthenticationFailed => ex
            response.exit_code = -1
            response.stderr    = "Authentication failure for user #{ex}"
          rescue Net::SSH::ConnectionTimeout, Timeout::Error
            response.exit_code = -1
            response.stderr    = "Connection timed out"
          rescue Errno::EHOSTUNREACH
            response.exit_code = -1
            response.stderr    = "Host unreachable"
          rescue Errno::ECONNREFUSED
            response.exit_code = -1
            response.stderr    = "Connection refused"
          rescue Net::SSH::Exception => ex
            response.exit_code = -1
            response.stderr    = ex.inspect
          end

          case response.exit_code
          when 0
            log.info "Successfully ran SSH command on: '#{host}' as: '#{options[:ssh][:user]}'"
          when -1
            log.info "Failed to run SSH command on: '#{host}' as: '#{options[:ssh][:user]}'"
          else
            log.info "Successfully ran SSH command on: '#{host}' as: '#{options[:ssh][:user]}' but it failed"
          end
        end
      end

      # Bootstrap a node
      #
      # @param [String] host
      #   the host to perform the action on
      #
      # @option options [Hash] :ssh
      #   * :user (String) a shell user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the shell user that will perform the bootstrap
      #   * :keys (Array, String) an array of key(s) to authenticate the ssh user with instead of a password
      #   * :timeout (Float) timeout value for SSH bootstrap (5.0)
      #   * :sudo (Boolean) run as sudo
      #
      # @return [HostConnector::Response]
      def bootstrap(host, options = {})
        options = options.reverse_merge(ssh: Hash.new)
        options[:ssh].reverse_merge!(sudo: true, timeout: 5.0)
        context = BootstrapContext::Unix.new(options)

        log.info "Bootstrapping host: #{host}"
        run(host, context.boot_command, options)
      end

      # Perform a chef client run on a node
      #
      # @param [String] host
      #   the host to perform the action on
      #
      # @option options [Hash] :ssh
      #   * :user (String) a shell user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the shell user that will perform the bootstrap
      #   * :keys (Array, String) an array of key(s) to authenticate the ssh user with instead of a password
      #   * :timeout (Float) timeout value for SSH bootstrap (5.0)
      #   * :sudo (Boolean) run as sudo
      #
      # @return [HostConnector::Response]
      def chef_client(host, options = {})
        run(host, "chef-client", options)
      end

      # Write your encrypted data bag secret on a node
      #
      # @param [String] host
      #   the host to perform the action on
      # @param [String] secret
      #   your organization's encrypted data bag secret
      #
      # @option options [Hash] :ssh
      #   * :user (String) a shell user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the shell user that will perform the bootstrap
      #   * :keys (Array, String) an array of key(s) to authenticate the ssh user with instead of a password
      #   * :timeout (Float) timeout value for SSH bootstrap (5.0)
      #   * :sudo (Boolean) run as sudo
      #
      # @return [HostConnector::Response]
      def put_secret(host, secret, options = {})
        cmd = "echo '#{secret}' > /etc/chef/encrypted_data_bag_secret; chmod 0600 /etc/chef/encrypted_data_bag_secret"
        run(host, cmd, options)
      end

      # Execute line(s) of Ruby code on a node using Chef's embedded Ruby
      #
      # @param [String] host
      #   the host to perform the action on
      # @param [Array<String>] command_lines
      #   An Array of lines of the command to be executed
      #
      # @option options [Hash] :ssh
      #   * :user (String) a shell user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the shell user that will perform the bootstrap
      #   * :keys (Array, String) an array of key(s) to authenticate the ssh user with instead of a password
      #   * :timeout (Float) timeout value for SSH bootstrap (5.0)
      #   * :sudo (Boolean) run as sudo
      #
      # @return [HostConnector::Response]
      def ruby_script(host, command_lines, options = {})
        run(host, "#{EMBEDDED_RUBY_PATH} -e \"#{command_lines.join(';')}\"", options)
      end

      # Uninstall Chef from a node
      #
      # @param [String] host
      #   the host to perform the action on
      #
      # @option options [Boolena] :skip_chef (false)
      #   skip removal of the Chef package and the contents of the installation
      #   directory. Setting this to true will only remove any data and configurations
      #   generated by running Chef client.
      # @option options [Hash] :ssh
      #   * :user (String) a shell user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the shell user that will perform the bootstrap
      #   * :keys (Array, String) an array of key(s) to authenticate the ssh user with instead of a password
      #   * :timeout (Float) timeout value for SSH bootstrap (5.0)
      #   * :sudo (Boolean) run as sudo (true)
      #
      # @return [HostConnector::Response]
      def uninstall_chef(host, options = {})
        options = options.reverse_merge(ssh: Hash.new)
        options[:ssh].reverse_merge!(sudo: true, timeout: 5.0)

        log.info "Uninstalling Chef from host: #{host}"
        run(host, CommandContext::UnixUninstall.command(options), options)
      end

      private

        def channel_exec(channel, command, host, response)
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
    end
  end
end
