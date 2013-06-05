require 'digest'

module Ridley::Chef
  # Borrowed and modified from: {https://github.com/opscode/chef/blob/11.4.0/lib/chef/digester.rb}
  class Digester
    class << self
      def instance
        @instance ||= new
      end

      def checksum_for_file(*args)
        instance.checksum_for_file(*args)
      end

      def md5_checksum_for_file(*args)
        instance.generate_md5_checksum_for_file(*args)
      end
    end

    def validate_checksum(*args)
      self.class.validate_checksum(*args)
    end

    def checksum_for_file(file)
      generate_checksum(file)
    end

    def generate_checksum(file)
      checksum_file(file, Digest::SHA256.new)
    end

    def generate_md5_checksum_for_file(file)
      checksum_file(file, Digest::MD5.new)
    end

    def generate_md5_checksum(io)
      checksum_io(io, Digest::MD5.new)
    end

    private

      def checksum_file(file, digest)
        File.open(file, 'rb') { |f| checksum_io(f, digest) }
      end

      def checksum_io(io, digest)
        while chunk = io.read(1024 * 8)
          digest.update(chunk)
        end
        digest.hexdigest
      end
  end
end
