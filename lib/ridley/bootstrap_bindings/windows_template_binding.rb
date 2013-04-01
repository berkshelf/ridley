# 
# Ridley::WindowsTemplateBinding
#   Represents a binding that will be evaluated as an ERB template. When bootstrapping
#   nodes, an instance of this class represents the customizable and necessary configurations
#   need by the Host in order to install and connect to Chef. By default, this class will be used
#   when WinRM is the best way to connect to the node.
# 
# @author Kyle Allan <kallan@riotgames.com>
# 
# Windows Specific code written by Seth Chisamore (<schisamo@opscode.com>) in knife-windows
# https://github.com/opscode/knife-windows/blob/3b8886ddcfb928ca0958cd05b22f8c3d78bee86e/lib/chef/knife/bootstrap/windows-chef-client-msi.erb
# https://github.com/opscode/knife-windows/blob/78d38bbed358ac20107fc2b5b427f4b5e52e5cb2/lib/chef/knife/core/windows_bootstrap_context.rb
module Ridley
  class WindowsTemplateBinding

    include Ridley::BootstrapBinding
    
    attr_reader :template_file

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
    # @option options [String] :template ('windows_omnibus')
    #   bootstrap template to use
    def initialize(options)
      options = Ridley::BootstrapBinding.default_options.merge(options)
      options[:template] ||= default_template
      Ridley::BootstrapBinding.validate_options(options)

      @template_file                  = options[:template]
      @bootstrap_proxy                = options[:bootstrap_proxy]
      @chef_version                   = options[:chef_version] ? options[:chef_version] : "latest"
      @validator_path                 = options[:validator_path]
      @encrypted_data_bag_secret_path = options[:encrypted_data_bag_secret_path]
      @server_url                     = options[:server_url]
      @validator_client               = options[:validator_client]
      @node_name                      = options[:node_name]
      @attributes                     = options[:attributes]
      @run_list                       = options[:run_list]
      @environment                    = options[:environment]
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
        body << %Q{encrypted_data_bag_secret "#{bootstrap_directory}\\encrypted_data_bag_secret"\n}
      end

      escape_and_echo(body)
    end

    # @return [String]
    def bootstrap_directory
      "C:\\chef"
    end

    # @return [String]
    def validation_key
      escape_and_echo(IO.read(File.expand_path(validator_path)).chomp)
    rescue Errno::ENOENT
      raise Errors::ValidatorNotFound, "Error bootstrapping: Validator not found at '#{validator_path}'"
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
      return unless encrypted_data_bag_secret_path

      escape_and_echo(IO.read(encrypted_data_bag_secret_path).chomp)
    rescue Errno::ENOENT
      raise Errors::EncryptedDataBagSecretNotFound, "Error bootstrapping: Encrypted data bag secret provided but not found at '#{encrypted_data_bag_secret_path}'"      
    end

    # Implements a Visual Basic script that attempts a simple
    # 'wget' to download the Chef msi
    # 
    # @return [String]
    def windows_wget_vb
      win_wget = <<-WGET
url = WScript.Arguments.Named("url")
path = WScript.Arguments.Named("path")
proxy = null
Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP")
Set wshShell = CreateObject( "WScript.Shell" )
Set objUserVariables = wshShell.Environment("USER")

'http proxy is optional
'attempt to read from HTTP_PROXY env var first
On Error Resume Next

If NOT (objUserVariables("HTTP_PROXY") = "") Then
proxy = objUserVariables("HTTP_PROXY")

'fall back to named arg
ElseIf NOT (WScript.Arguments.Named("proxy") = "") Then
proxy = WScript.Arguments.Named("proxy")
End If

If NOT isNull(proxy) Then
'setProxy method is only available on ServerXMLHTTP 6.0+
Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP.6.0")
objXMLHTTP.setProxy 2, proxy
End If

On Error Goto 0

objXMLHTTP.open "GET", url, false
objXMLHTTP.send()
If objXMLHTTP.Status = 200 Then
Set objADOStream = CreateObject("ADODB.Stream")
objADOStream.Open
objADOStream.Type = 1
objADOStream.Write objXMLHTTP.ResponseBody
objADOStream.Position = 0
Set objFSO = Createobject("Scripting.FileSystemObject")
If objFSO.Fileexists(path) Then objFSO.DeleteFile path
Set objFSO = Nothing
objADOStream.SaveToFile path
objADOStream.Close
Set objADOStream = Nothing
End if
Set objXMLHTTP = Nothing
WGET
      escape_and_echo(win_wget)
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
      escape_and_echo(MultiJson.encode attributes.merge(run_list: run_list))
    end

    # @return [String]
    def set_path
      "SET \"PATH=%PATH%;C:\\ruby\\bin;C:\\opscode\\chef\\bin;C:\\opscode\\chef\\embedded\\bin\"\n"
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
