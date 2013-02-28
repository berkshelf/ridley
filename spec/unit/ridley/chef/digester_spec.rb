# Borrowed and modified from: {https://github.com/opscode/chef/blob/11.4.0/spec/unit/digester_spec.rb}

require 'spec_helper'

describe Ridley::Chef::Digester do
  before(:each) do
    @cache = described_class.instance
  end

  describe "when computing checksums of cookbook files and templates" do
    it "proxies the class method checksum_for_file to the instance" do
      @cache.should_receive(:checksum_for_file).with("a_file_or_a_fail")
      described_class.checksum_for_file("a_file_or_a_fail")
    end

    it "generates a checksum from a non-file IO object" do
      io = StringIO.new("riseofthemachines\nriseofthechefs\n")
      expected_md5 = '0e157ac1e2dd73191b76067fb6b4bceb'
      @cache.generate_md5_checksum(io).should == expected_md5
    end
  end
end
