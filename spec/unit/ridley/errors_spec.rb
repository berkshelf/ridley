require 'spec_helper'

describe Ridley::Errors do
  describe Ridley::Errors::HTTPError do
    describe "ClassMethods" do
      subject { Ridley::Errors::HTTPError }

      before(:each) do
        @original = Ridley::Errors::HTTPError.class_variable_get :@@error_map
        Ridley::Errors::HTTPError.class_variable_set :@@error_map, Hash.new
      end

      after(:each) do
        Ridley::Errors::HTTPError.class_variable_set :@@error_map, @original
      end

      describe "::register_error" do
        it "adds an item to the error map" do
          subject.register_error(400)

          expect(subject.error_map.size).to eq(1)
        end

        it "adds a key of the given status code with a value of the class inheriting from HTTPError" do
          class RidleyTestHTTPError < Ridley::Errors::HTTPError
            register_error(400)
          end

          expect(subject.error_map[400]).to eql(RidleyTestHTTPError)
        end
      end
    end

    context "with an HTML error payload" do
      subject { Ridley::Errors::HTTPError.new(:body => "<html><body><h1>Redirected</h1></body></html>") }

      it "has an HTML body" do
        expect(subject.message).to eq("<html><body><h1>Redirected</h1></body></html>")
      end
    end
  end
end
