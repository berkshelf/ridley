require 'spec_helper'

describe Ridley::Search do\
  let(:client) do
    double('client',
      connection: double('connection')
    )
  end
  let(:index) { :role }
  let(:query) { "*:*" }
  let(:response) do
    double(
      "response", 
      body: {
        rows: Array.new,
        total: 0,
        start: 0
      }
    )
  end

  describe "ClassMethods" do
    subject { Ridley::Search }

    describe "::indexes" do
      it "sends a get request to the client to receive the indexes" do
        client.connection.should_receive(:get).with("search").and_return(response)

        subject.indexes(client)
      end
    end
  end

  describe "#run" do
    subject do
      Ridley::Search.new(client, index, query)
    end

    it "sends a get request to the client to the index's location with the given query" do
      client.connection.should_receive(:get).with("search/#{index}", q: query).and_return(response)

      subject.run
    end

    context "when 'sort' is set" do
      let(:sort) { "DESC" }
      before(:each) { subject.sort = sort }

      it "sends a get request to the client with a query parameter for 'set'" do
        client.connection.should_receive(:get).with("search/#{index}", q: query, sort: sort).and_return(response)

        subject.run
      end
    end

    context "when 'start' is set" do
      let(:start) { 1 }
      before(:each) { subject.start = start }

      it "sends a get request to the client with a query parameter for 'start'" do
        client.connection.should_receive(:get).with("search/#{index}", q: query, start: start).and_return(response)

        subject.run
      end
    end

    context "when 'rows' is set" do
      let(:rows) { 1 }
      before(:each) { subject.rows = rows }

      it "sends a get request to the client with a query parameter for 'rows'" do
        client.connection.should_receive(:get).with("search/#{index}", q: query, rows: rows).and_return(response)

        subject.run
      end
    end

    context "when ':node' is given as index" do
      let(:index) { :node }
      let(:response) do
        double(
          "response", 
          body: {
            rows: [
              {
                chef_type: "node",
                json_class: "Chef::Node",
                name: "ridley-one",
                chef_environment: "_default",
                automatic: {},
                normal: {},
                default: {},
                override: {},
                run_list: [
                  "recipe[one]",
                  "recipe[two]"
                ]
              }
            ],
            total: 1,
            start: 0
          }
        )
      end

      subject { Ridley::Search.new(client, index, query) }

      it "returns an array of Ridley::NodeResource" do
        client.connection.should_receive(:get).with("search/#{index}", q: query).and_return(response)
        result = subject.run

        result.should be_a(Array)
        result.should each be_a(Ridley::NodeResource)
      end
    end

    context "when ':role' is given as index" do
      let(:index) { :role }
      let(:response) do
        double(
          "response", 
          body: {
            rows: [
              {
                chef_type: "role",
                json_class: "Chef::Role",
                name: "ridley-role-one",
                description: "",
                default_attributes: {},
                override_attributes: {},
                run_list: [],
                env_run_lists: {}
              }
            ],
            total: 1,
            start: 0
          }
        )
      end

      subject { Ridley::Search.new(client, index, query) }

      it "returns an array of Ridley::RoleResource" do
        client.connection.should_receive(:get).with("search/#{index}", q: query).and_return(response)
        result = subject.run

        result.should be_a(Array)
        result.should each be_a(Ridley::RoleResource)
      end
    end

    context "when ':environment' is given as index" do
      let(:index) { :environment }
      let(:response) do
        double(
          "response", 
          body: {
            rows: [
              {
                chef_type: "environment",
                json_class: "Chef::Environment",
                name: "ridley-env-test",
                description: "ridley testing environment",
                default_attributes: {},
                override_attributes: {},
                cookbook_versions: {}
              }
            ],
            total: 1,
            start: 0
          }
        )
      end

      subject { Ridley::Search.new(client, index, query) }

      it "returns an array of Ridley::EnvironmentResource" do
        client.connection.should_receive(:get).with("search/#{index}", q: query).and_return(response)
        result = subject.run

        result.should be_a(Array)
        result.should each be_a(Ridley::EnvironmentResource)
      end
    end

    context "when ':client' is given as index" do
      let(:index) { :client }
      let(:response) do
        double(
          "response", 
          body: {
            rows: [
              {
                chef_type: "client",
                name: nil,
                admin: false,
                validator: false,
                certificate: "-----BEGIN CERTIFICATE-----\nMIIDOjCCAqOgAwIBAgIE47eOmDANBgkqhkiG9w0BAQUFADCBnjELMAkGA1UEBhMC\nVVMxEzARBgNVBAgMCldhc2hpbmd0b24xEDAOBgNVBAcMB1NlYXR0bGUxFjAUBgNV\nBAoMDU9wc2NvZGUsIEluYy4xHDAaBgNVBAsME0NlcnRpZmljYXRlIFNlcnZpY2Ux\nMjAwBgNVBAMMKW9wc2NvZGUuY29tL2VtYWlsQWRkcmVzcz1hdXRoQG9wc2NvZGUu\nY29tMCAXDTEyMTAwOTAwMTUxNVoYDzIxMDExMTA0MDAxNTE1WjCBnTEQMA4GA1UE\nBxMHU2VhdHRsZTETMBEGA1UECBMKV2FzaGluZ3RvbjELMAkGA1UEBhMCVVMxHDAa\nBgNVBAsTE0NlcnRpZmljYXRlIFNlcnZpY2UxFjAUBgNVBAoTDU9wc2NvZGUsIElu\nYy4xMTAvBgNVBAMUKFVSSTpodHRwOi8vb3BzY29kZS5jb20vR1VJRFMvY2xpZW50\nX2d1aWQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCqB9KEGzl7Wcm/\nwz/x8HByZANCn6WQC+R12qQso5I6nLbTNkRP668jXG3j0R5/F5i/KearAB9ePzL/\nQe3iHtwW6u1qLI1hVNFNB+I1fGu1p6fZyIOjnLn3bqsbOkBplHOIqHsp4GVSsHKb\nD32UXZDa9S9ZFXnR4iT6hUGm5895ReZG9TDiHvBpi9NJFDZXz+AQ6JuQY8UgYMMA\nm80KbO8/NJlXbRW+siRuvr+LIsi9Mx4i63pBWAN46my291rQU31PF3IB+btfGtR/\nyDWDgMSB37bTzZeOf1Dg9fpl2vIXyu3PoHER0oYmrMQbrdwAt7qCHZNuNWn51WPb\n1PHxXL1rAgMBAAEwDQYJKoZIhvcNAQEFBQADgYEAGnJUVAv951fUhGyPOrl+LbQG\nqgchMwIn7oDLE863e66BYTDj7koK3jjhx3EBkrT2vt/xS4yW0ZRV1BNqfnNKWbBq\nMNQiKkYdTr+oq2O3plOg/q/M1eG1B5pxGXqvH0O76DVWQcV/svO+HQEi1n8y5UQd\n+pBJCygpuv78wPCM+c4=\n-----END CERTIFICATE-----\n",
                public_key: nil,
                private_key: nil,
                orgname: "ridley"
              }
            ],
            total: 1,
            start: 0
          }
        )
      end

      subject { Ridley::Search.new(client, index, query) }

      it "returns an array of Ridley::ClientResource" do
        client.connection.should_receive(:get).with("search/#{index}", q: query).and_return(response)
        result = subject.run

        result.should be_a(Array)
        result.should each be_a(Ridley::ClientResource)
      end
    end
  end
end
