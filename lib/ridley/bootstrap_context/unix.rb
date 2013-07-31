module Ridley
  module BootstrapContext
    # Represents a binding that will be evaluated as an ERB template. When bootstrapping
    # nodes, an instance of this class represents the customizable and necessary configurations
    # needed by the Host in order to install and connect to Chef. By default, this class will be used
    # when SSH is the best way to connect to the node.
    class Unix < BootstrapContext::Base
      attr_reader :sudo

      # @option options [Boolean] :sudo (true)
      #   bootstrap with sudo (default: true)
      def initialize(options = {})
        options = options.reverse_merge(sudo: true)
        @sudo   = options[:sudo]
        super(options)
      end

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
          body << %Q{encrypted_data_bag_secret "#{bootstrap_directory}/encrypted_data_bag_secret"\n}
        end

        body
      end

      # @return [String]
      def bootstrap_directory
        "/etc/chef"
      end

      # @return [String]
      def chef_run
        "chef-client -j #{bootstrap_directory}/first-boot.json -E #{environment}"
      end

      # @return [String]
      def default_template
        templates_path.join('unix_omnibus.erb').to_s
      end
    end
  end
end
