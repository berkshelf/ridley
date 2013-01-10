require 'spec_helper'

describe Ridley::Middleware::ParseJson do
  let(:server_url) { "https://api.opscode.com/organizations/vialstudios/" }

  describe "ClassMethods" do
    subject { Ridley::Middleware::ParseJson }

    describe "::response_type" do
      it "returns the first element of the response content-type" do
        env = double('env')
        env.stub(:[]).with(:response_headers).and_return(
          'content-type' => 'text/html; charset=utf-8'
        )

        subject.response_type(env).should eql("text/html")
      end
    end

    describe "::json_response?" do
      it "returns true if the value of content-type includes 'application/json' and the body looks like JSON" do
        env = double('env')
        env.stub(:[]).with(:response_headers).and_return(
          'content-type' => 'application/json; charset=utf8'
        )
        subject.should_receive(:looks_like_json?).with(env).and_return(true)

        subject.json_response?(env).should be_true
      end

      it "returns false if the value of content-type includes 'application/json' but the body does not look like JSON" do
        env = double('env')
        env.stub(:[]).with(:response_headers).and_return(
          'content-type' => 'application/json; charset=utf8'
        )
        subject.should_receive(:looks_like_json?).with(env).and_return(false)

        subject.json_response?(env).should be_false
      end

      it "returns false if the value of content-type does not include 'application/json'" do
        env = double('env')
        env.stub(:[]).with(:response_headers).and_return(
          'content-type' => 'text/plain'
        )

        subject.json_response?(env).should be_false
      end
    end

    describe "::looks_like_json?" do
      let(:env) { double('env') }

      it "returns true if the given string contains JSON brackets" do
        env.stub(:[]).with(:body).and_return("{\"name\":\"jamie\"}")

        subject.looks_like_json?(env).should be_true
      end

      it "returns false if the given string does not contain JSON brackets" do
        env.stub(:[]).with(:body).and_return("name")

        subject.looks_like_json?(env).should be_false
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
