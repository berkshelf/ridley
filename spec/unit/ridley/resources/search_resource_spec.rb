require 'spec_helper'

describe Ridley::SearchResource do
  describe "ClassMethods" do
    subject { described_class }

    describe "::build_query" do
      let(:query_string) { "*:*" }
      let(:options) { Hash.new }

      it "contains a 'q' key/value" do
        result = subject.build_query(query_string, options)

        result.should have_key(:q)
        result[:q].should eql(query_string)
      end

      context "when :sort option is set" do
        before { options[:sort] = "DESC" }

        it "contains a 'sort' key/value" do
          result = subject.build_query(query_string, options)

          result.should have_key(:sort)
          result[:sort].should eql("DESC")
        end
      end

      context "when :start option is set" do
        before { options[:start] = 1 }

        it "contains a 'start' key/value" do
          result = subject.build_query(query_string, options)

          result.should have_key(:start)
          result[:start].should eql(1)
        end
      end

      context "when :rows option is set" do
        before { options[:rows] = 1 }

        it "contains a 'rows' key/value" do
          result = subject.build_query(query_string, options)

          result.should have_key(:rows)
          result[:rows].should eql(1)
        end
      end
    end

    describe "::build_param_string" do
      let(:query) { "*:*" }
      let(:options) { Hash.new }

      subject { described_class.build_param_string(query, options) }

      it "returns a string containing the query string" do
        expect(subject).to eq("?q=#{query}")
      end

      context "when the :start option is given" do
        let(:start) { 10 }
        let(:options) { { start: start } }

        it "contains the start query param" do
          expect(subject).to eq("?q=#{query}&start=#{start}")
        end
      end

      context "when the :sort option is given" do
        let(:sort) { "DESC" }
        let(:options) { { sort: sort } }

        it "contains the sort query param" do
          expect(subject).to eq("?q=#{query}&sort=#{sort}")
        end
      end

      context "when the :rows option is given" do
        let(:rows) { 20 }
        let(:options) { { rows: rows } }

        it "contains the rows query param" do
          expect(subject).to eq("?q=#{query}&rows=#{rows}")
        end
      end
    end

    describe "::query_uri" do
      it "returns a URI path containing the search resource path and index" do
        subject.query_uri(:nodes).should eql("search/nodes")
      end
    end
  end

  let(:connection) { double('chef-connection') }
  subject { described_class.new(double('registry')) }
  before  { subject.stub(connection: connection) }

  describe "#indexes" do
    let(:response) do
      double(body: {
        node: "http://localhost:4000/search/node",
        role: "http://localhost:4000/search/role",
        client: "http://localhost:4000/search/client",
        users: "http://localhost:4000/search/users"
      })
    end

    before do
      connection.stub(:get).with(described_class.resource_path).and_return(response)
    end

    it "performs a GET to the search resource_path" do
      connection.should_receive(:get).with(described_class.resource_path).and_return(response)
      subject.indexes
    end

    it "contains a key for each index" do
      subject.indexes.should have(4).items
    end
  end

  describe "#run" do
    let(:index) { :role }
    let(:query_string) { "*:*" }
    let(:options) { Hash.new }
    let(:response) do
      double(body: {
        rows: Array.new,
        total: 0,
        start: 0
      })
    end
    let(:registry) { double("registry", :[] => nil) }

    let(:run) { subject.run(index, query_string, registry) }

    before do
      connection.stub(:get).and_return(response)
    end

    it "builds a query and runs it against the index's resource path" do
      query     = double('query')
      query_uri = double('query-uri')
      described_class.should_receive(:build_query).with(query_string, options).and_return(query)
      described_class.should_receive(:query_uri).with(index).and_return(query_uri)
      connection.should_receive(:get).with(query_uri, query).and_return(response)

      subject.run(index, query_string, options)
    end

    context "when :node is the given index" do
      let(:index) { :node }
      let(:response) do
        double(body: {
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
        })
      end

      it "returns an array of Ridley::NodeObject" do
        result = run

        result.should be_a(Array)
        result.should each be_a(Ridley::NodeObject)
      end

      context "after the search has executed and results are returned" do
        let(:search_results) { subject.run(index, query_string, registry) }

        it "Ridley::NodeObject instances contain the results" do
          first_result = search_results.first
          first_result.name.should eq("ridley-one")
        end
      end
    end

    context "when :role is the given index" do
      let(:index) { :role }
      let(:response) do
        double(body: {
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
        })
      end

      it "returns an array of Ridley::RoleObject" do
        result = run

        result.should be_a(Array)
        result.should each be_a(Ridley::RoleObject)
      end

      context "after the search has executed and results are returned" do
        let(:search_results) { subject.run(index, query_string, registry) }

        it "Ridley::RoleObject instances contain the results" do
          first_result = search_results.first
          first_result.name.should eq("ridley-role-one")
        end
      end
    end

    context "when :environment is the given index" do
      let(:index) { :environment }
      let(:response) do
        double(body: {
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
        })
      end

      it "returns an array of Ridley::EnvironmentObject" do
        result = run

        result.should be_a(Array)
        result.should each be_a(Ridley::EnvironmentObject)
      end

      context "after the search has executed and results are returned" do
        let(:search_results) { subject.run(index, query_string, registry) }

        it "Ridley::EnvironmentObject instances contain the results" do
          first_result = search_results.first
          first_result.name.should eq("ridley-env-test")
        end
      end
    end

    context "when :client is the given index" do
      let(:index) { :client }
      let(:response) do
        double(body: {
          rows: [
            {
              chef_type: "client",
              name: "ridley-client-test",
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
        })
      end

      it "returns an array of Ridley::ClientObject" do
        result = run

        result.should be_a(Array)
        result.should each be_a(Ridley::ClientObject)
      end

      context "after the search has executed and results are returned" do
        let(:search_results) { subject.run(index, query_string, registry) }

        it "Ridley::ClientObject instances contain the results" do
          first_result = search_results.first
          first_result.name.should eq("ridley-client-test")
        end
      end
    end
  end
end
