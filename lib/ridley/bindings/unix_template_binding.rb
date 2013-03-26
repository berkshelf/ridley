module Ridley
  # @author Kyle Allan <kallan@riotgames.com>
  class UnixTemplateBinding < Ridley::Binding

    attr_reader :sudo
    attr_reader :hints

    def initialize(options = {})
      options = Ridley::Binding.default_options.merge(options)
      options[:template] ||= default_template
      self.class.validate_options(options)

      @template_file                  = options[:template]
      @bootstrap_proxy                = options[:bootstrap_proxy]
      @chef_version                   = options[:chef_version]
      @sudo                           = options[:sudo]
      @validator_path                 = options[:validator_path]
      @encrypted_data_bag_secret_path = options[:encrypted_data_bag_secret_path]
      @hints                          = options[:hints]
      @server_url                     = options[:server_url]
      @validator_client               = options[:validator_client]
      @node_name                      = options[:node_name]
      @attributes                     = options[:attributes]
      @run_list                       = options[:run_list]
      @environment                    = options[:environment]
    end

    # @return [String]
    def boot_command
      cmd = template.evaluate(self)

      if sudo
        cmd = "sudo #{cmd}"
      end

      cmd
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

    def bootstrap_directory
      "/etc/chef"
    end

    def chef_run
      "chef-client -j #{bootstrap_directory}/first-boot.json -E #{environment}"
    end

    def default_template
      templates_path.join('unix_omnibus.erb').to_s
    end
  end
end
