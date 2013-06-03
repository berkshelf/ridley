require 'spec_helper'

describe Ridley::Mixin::ShellOut do
  describe "shell_out" do
    let(:command) { "ls" }

    subject(:result) { described_class.shell_out(command) }

    it "returns a ShellOut::Response" do
      expect(result).to be_a(described_class::Response)
    end

    its(:stdout) { should be_a(String) }
    its(:stderr) { should be_a(String) }
    its(:exitstatus) { should be_a(Fixnum) }
    its(:pid) { should be_a(Fixnum) }
    its(:success?) { should be_true }
    its(:error?) { should be_false }

    context "when on MRI" do
      before { described_class.stub(jruby?: false) }

      it "delegates to #mri_out" do
        described_class.should_receive(:mri_out).with(command)
        result
      end
    end

    context "when on JRuby" do
      before { described_class.stub(jruby?: true) }

      it "delegates to #jruby_out" do
        described_class.should_receive(:jruby_out).with(command)
        result
      end
    end
  end
end
