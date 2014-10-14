require 'spec_helper'

module Ridley
  describe Mixin::FromFile do
    describe '.from_file' do
      context 'when there is bad Ruby in the file' do
        let(:instance) { Class.new { include Ridley::Mixin::FromFile }.new }

        before do
          File.stub(:exists?).and_return(true)
          File.stub(:readable?).and_return(true)
          IO.stub(:read).and_return('invalid Ruby code')
        end

        it 'raises a FromFileParserError' do
          expect {
            instance.from_file('/path')
          }.to raise_error(Errors::FromFileParserError)
        end

        it 'includes the backtrace from the original error' do
          expect { instance.from_file('/path') }.to raise_error { |error|
            expect(error.message).to include("undefined local variable or method `code' for")
            expect(error.backtrace).to include("/path:1:in `block in from_file'")
          }
        end
      end
    end
  end
end
