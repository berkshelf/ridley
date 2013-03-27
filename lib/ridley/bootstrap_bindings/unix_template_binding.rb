# 
# Ridley::UnixTemplateBinding
#   Represents a binding that will be evaluated as an ERB template. When bootstrapping
#   nodes, an instance of this class represents the customizable and necessary configurations
#   need by the Host in order to install and connect to Chef. By default, this class will be used
#   when SSH is the best way to connect to the node.
# 
# @author Kyle Allan <kallan@riotgames.com>
# 
module Ridley
  class UnixTemplateBinding < Ridley::BootstrapBinding

    attr_reader :sudo
    attr_reader :hints

    # @option options [String] :validator_client
    # @option options [String] :validator_path
    #   filepath to the validator used to bootstrap the node (required)
    # @option options [String] :bootstrap_proxy (nil)
    #   URL to a proxy server to bootstrap through
    # @option options [String] :encrypted_data_bag_secret_path (nil)
    #   filepath on your host machine to your organizations encrypted data bag secret
    # @option options [Hash] :hints (Hash.new)
    #   a hash of Ohai hints to place on the bootstrapped node
    # @option options [Hash] :attributes (Hash.new)
    #   a hash of attributes to use in the first Chef run
    # @option options [Array] :run_list (Array.new)
    #   an initial run list to bootstrap with
    # @option options [String] :chef_version (nil)
    #   version of Chef to install on the node
    # @option options [String] :environment ('_default')
    #   environment to join the node to
    # @option options [Boolean] :sudo (true)
    #   bootstrap with sudo (default: true)
    # @option options [String] :template ('unix_omnibus')
    #   bootstrap template to use
    def initialize(options = {})
      options = Ridley::BootstrapBinding.default_options.merge(options)
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
