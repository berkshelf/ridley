module Ridley
  # @author Kyle Allan <kallan@riotgames.com>
  class WindowsTemplateBinding < Ridley::Binding
    
    attr_reader :template_file

    def initialize(options)
      @template_file = default_template
    end

    def bootstrap_directory
      "C:\\chef"
    end

    def chef_run
      "chef-client -j #{bootstrap_directory}\\first-boot.json -E #{environment}"
    end

    def default_template
      templates_path.join('windows_omnibus.erb').to_s
    end
  end
end
