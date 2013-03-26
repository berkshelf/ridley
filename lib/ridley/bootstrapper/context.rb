require 'erubis'

module Ridley
  class Bootstrapper
    # @author Jamie Winsor <reset@riotgames.com>
    class Context
      class << self
        def create(host, options = {})
          connector = Connector.best_connector_for(host)
          case connector.to_s
          when Ridley::Connector::SSH.to_s
            template_binding = Ridley::UnixTemplateBinding.new(options)
          when Ridley::Connector::WinRM.to_s
            template_binding = Ridley::WindowsTemplateBinding.new(options)
          end
          new(host, connector, template_binding)
        end
      end

      # @return [String]
      attr_reader :host
      # @return [Ridley::Connector]
      attr_reader :connector
      # @return [Ridley::Binding]
      attr_reader :template_binding

      # @param [String] host
      #   name of the node as identified in Chef
      # @param [Ridley::Connector] connector
      #   either the SSH or WinRM Connector class
      # @param [Ridley::Binding] template_binding
      #   an instance of either the UnixTemplateBinding or WindowsTemplateBinding class
      def initialize(host, connector, template_binding)
        @host                           = host
        @connector                      = connector
        @template_binding               = template_binding
      end

      # @return [String]
      def clean_command
        "rm /etc/chef/first-boot.json; rm /etc/chef/validation.pem"
      end
    end
  end
end
