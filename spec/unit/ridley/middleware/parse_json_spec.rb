require 'spec_helper'

describe Ridley::Middleware::ParseJson do
  let(:server_url) { "https://api.opscode.com/organizations/vialstudios/" }

  describe "ClassMethods" do
    subject { Ridley::Middleware::ParseJson }

    describe "::response_type" do
      it "returns the first element of the response content-type" do
        env = double('env')
        allow(env).to receive(:[]).with(:response_headers).and_return(
          'content-type' => 'text/html; charset=utf-8'
        )

        expect(subject.response_type(env)).to eql("text/html")
      end
    end

    describe "::json_response?" do
      it "returns true if the value of content-type includes 'application/json' and the body looks like JSON" do
        env = double('env')
        allow(env).to receive(:[]).with(:response_headers).and_return(
          'content-type' => 'application/json; charset=utf8'
        )
        expect(subject).to receive(:looks_like_json?).with(env).and_return(true)

        expect(subject.json_response?(env)).to be_truthy
      end

      it "returns false if the value of content-type includes 'application/json' but the body does not look like JSON" do
        env = double('env')
        allow(env).to receive(:[]).with(:response_headers).and_return(
          'content-type' => 'application/json; charset=utf8'
        )
        expect(subject).to receive(:looks_like_json?).with(env).and_return(false)

        expect(subject.json_response?(env)).to be_falsey
      end

      it "returns false if the value of content-type does not include 'application/json'" do
        env = double('env')
        allow(env).to receive(:[]).with(:response_headers).and_return(
          'content-type' => 'text/plain'
        )

        expect(subject.json_response?(env)).to be_falsey
      end
    end

    describe "::looks_like_json?" do
      let(:env) { double('env') }

      it "returns true if the given string contains JSON brackets" do
        allow(env).to receive(:[]).with(:body).and_return("{\"name\":\"jamie\"}")

        expect(subject.looks_like_json?(env)).to be_truthy
      end

      it "returns false if the given string does not contain JSON brackets" do
        allow(env).to receive(:[]).with(:body).and_return("name")

        expect(subject.looks_like_json?(env)).to be_falsey
      end
    end
  end

  subject do
    Faraday.new(server_url) do |conn|
      conn.response :json
      conn.adapter Faraday.default_adapter
    end
  end
end
