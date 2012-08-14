require 'spec_helper'

describe Ridley::Middleware::ChefResponse do
  let(:server_url) { "https://api.opscode.com/organizations/vialstudios/" }

  subject do
    Faraday.new(server_url) do |conn|
      conn.response :chef_response
      conn.adapter Faraday.default_adapter
    end
  end

  let(:chef_bad_request) do
    {
      status: 400,
      body: generate_normalized_json(error: "400 - Bad Request: Valid X-CHEF-VERSION header is required.")
    }
  end

  let(:chef_unauthorized) do
    {
      status: 401, 
      body: generate_normalized_json(error: "401 - Unauthorized.  You must properly authenticate your API requests!")
    }
  end

  let(:chef_forbidden) do
    {
      status: 403, 
      body: generate_normalized_json(error: "403 - Forbidden.")
    }
  end

  let(:chef_not_found) do
    {
      status: 404,
      body: generate_normalized_json(error: [ "No routes match the request: /organizations/vialstudios/cookbookss/not_existant" ])
    }
  end

  let(:chef_conflict) do
    {
      status: 409,
      body: generate_normalized_json(error: "409 - Conflict.")
    }
  end

  describe "400 Bad Request" do
    before(:each) do
      stub_request(:get, File.join(server_url, 'cookbooks')).to_return(chef_bad_request)
    end

    it "raises a Ridley::Errors::HTTPBadRequest" do
      lambda {
        subject.get('cookbooks')
      }.should raise_error(Ridley::Errors::HTTPBadRequest)
    end

    it "should have the body of the response as the error's message" do
      lambda {
        subject.get('cookbooks')
      }.should raise_error("errors: '400 - Bad Request: Valid X-CHEF-VERSION header is required.'")
    end
  end

  describe "401 Unauthorized" do
    before(:each) do
      stub_request(:get, File.join(server_url, 'cookbooks')).to_return(chef_unauthorized)
    end

    it "raises a Ridley::Errors::HTTPUnauthorized" do
      lambda {
        subject.get('cookbooks')
      }.should raise_error(Ridley::Errors::HTTPUnauthorized)
    end

    it "should have the body of the response as the error's message" do
      lambda {
        subject.get('cookbooks')
      }.should raise_error("errors: '401 - Unauthorized.  You must properly authenticate your API requests!'")
    end
  end

  describe "403 Forbidden" do
    before(:each) do
      stub_request(:get, File.join(server_url, 'cookbooks')).to_return(chef_forbidden)
    end

    it "raises a Ridley::Errors::HTTPForbidden" do
      lambda {
        subject.get('cookbooks')
      }.should raise_error(Ridley::Errors::HTTPForbidden)
    end

    it "should have the body of the response as the error's message" do
      lambda {
        subject.get('cookbooks')
      }.should raise_error("errors: '403 - Forbidden.'")
    end
  end

  describe "404 Not Found" do
    before(:each) do
      stub_request(:get, File.join(server_url, 'not_existant_route')).to_return(chef_not_found)
    end

    it "raises a Ridley::Errors::HTTPNotFound" do      
      lambda {
        subject.get('not_existant_route')
      }.should raise_error(Ridley::Errors::HTTPNotFound)
    end

    it "should have the body of the response as the error's message" do
      lambda {
        subject.get('not_existant_route')
      }.should raise_error(Ridley::Errors::HTTPNotFound, "errors: 'No routes match the request: /organizations/vialstudios/cookbookss/not_existant'")
    end
  end

  describe "409 Conflict" do
    before(:each) do
      stub_request(:get, File.join(server_url, 'cookbooks')).to_return(chef_conflict)
    end

    it "raises a Ridley::Errors::HTTPForbidden" do
      lambda {
        subject.get('cookbooks')
      }.should raise_error(Ridley::Errors::HTTPConflict)
    end

    it "should have the body of the response as the error's message" do
      lambda {
        subject.get('cookbooks')
      }.should raise_error("errors: '409 - Conflict.'")
    end
  end

  describe "200 OK" do
    pending
  end
end
