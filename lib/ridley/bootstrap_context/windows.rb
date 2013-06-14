module Ridley
  module BootstrapContext
    # Represents a binding that will be evaluated as an ERB template. When bootstrapping
    # nodes, an instance of this class represents the customizable and necessary configurations
    # needed by the Host in order to install and connect to Chef. By default, this class will be used
    # when WinRM is the best way to connect to the node.
    #
    # Windows Specific code written by Seth Chisamore (<schisamo@opscode.com>) in knife-windows
    # https://github.com/opscode/knife-windows/blob/3b8886ddcfb928ca0958cd05b22f8c3d78bee86e/lib/chef/knife/bootstrap/windows-chef-client-msi.erb
    # https://github.com/opscode/knife-windows/blob/78d38bbed358ac20107fc2b5b427f4b5e52e5cb2/lib/chef/knife/core/windows_bootstrap_context.rb
    class Windows < BootstrapContext::Base
      # @return [String]
      def boot_command
        template.evaluate(self)
      end

      # @return [String]
      def chef_config
        body = <<-CONFIG
  log_level        :info
  log_location     STDOUT
  chef_server_url  "#{server_url}"
  validation_client_name "#{validator_client}"
  CONFIG

        if node_name.present?
          body << %Q{node_name "#{node_name}"\n}
        else
          body << "# Using default node name (fqdn)\n"
        end

        if bootstrap_proxy.present?
          body << %Q{http_proxy        "#{bootstrap_proxy}"\n}
          body << %Q{https_proxy       "#{bootstrap_proxy}"\n}
        end

        if encrypted_data_bag_secret.present?
          body << %Q{encrypted_data_bag_secret '#{bootstrap_directory}\\encrypted_data_bag_secret'\n}
        end

        escape_and_echo(body)
      end

      # @return [String]
      def bootstrap_directory
        "C:\\chef"
      end

      # @return [String]
      def validation_key
        escape_and_echo(super)
      end

      # @return [String]
      def chef_run
        "chef-client -j #{bootstrap_directory}\\first-boot.json -E #{environment}"
      end

      # @return [String]
      def default_template
        templates_path.join('windows_omnibus.erb').to_s
      end

      # @return [String]
      def encrypted_data_bag_secret
        return unless @encrypted_data_bag_secret

        escape_and_echo(@encrypted_data_bag_secret)
      end

      # Implements a Powershell script that attempts a simple
      # 'wget' to download the Chef msi
      #
      # @return [String]
      def windows_wget_powershell
        win_wget_ps = <<-WGET_PS
  param(
   [String] $remoteUrl,
   [String] $localPath
  )

  $webClient = new-object System.Net.WebClient;

  $webClient.DownloadFile($remoteUrl, $localPath);
  WGET_PS

        escape_and_echo(win_wget_ps)
      end

      # @return [String]
      def install_chef
        'msiexec /qb /i "%LOCAL_DESTINATION_MSI_PATH%"'
      end

      # @return [String]
      def first_boot
        escape_and_echo(super)
      end

      # @return [String]
      def env_path
        "C:\\opscode\\chef\\bin;C:\\opscode\\chef\\embedded\\bin"
      end

      # @return [String]
      def local_download_path
        "%TEMP%\\chef-client-#{chef_version}.msi"
      end

      # escape WIN BATCH special chars
      # and prefixes each line with an
      # echo
      def escape_and_echo(file_contents)
        file_contents.gsub(/^(.*)$/, 'echo.\1').gsub(/([(<|>)^])/, '^\1')
      end
    end
  end
end
