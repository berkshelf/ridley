module Ridley::Mixin
  # Inspired by and dependency-free replacement for
  # {https://github.com/opscode/chef/blob/11.4.0/lib/chef/mixin/checksum.rb}
  module Checksum
    # @param [String] file
    #
    # @return [String]
    def checksum(file)
      Ridley::Chef::Digester.checksum_for_file(file)
    end
  end
end
