require 'spec_helper'

describe Ridley::Connector::WinRM do

  describe "ClassMethods" do
    subject { Ridley::Connector::WinRM }
    
    describe "::start" do
      let(:options) do
        {
          user: "Administrator",
          password: "password1"
        }
      end

      it "evaluates within the context of a new WinRM and returns the last item in the block" do
        result = subject.start([], options) do |winrm|
          winrm.run("dir")
        end
        result.should be_a(Ridley::Connector::WinRM::ResponseSet)
      end
    end
  end
end
