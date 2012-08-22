require 'spec_helper'

describe Ridley::Search do
  let(:connection) { double('connection') }
  let(:index) { :role }
  let(:query) { "*:*" }
  let(:response) { double("response", body: Hash.new) }

  describe "ClassMethods" do
    subject { Ridley::Search }

    describe "::indexes" do
      it "sends a get request to the connection to receive the indexes" do
        connection.should_receive(:get).with("search").and_return(response)

        subject.indexes(connection)
      end
    end
  end

  describe "#run" do
    subject do
      Ridley::Search.new(connection, index, query)
    end

    it "sends a get request to the connection to the index's location with the given query" do
      connection.should_receive(:get).with("search/#{index}", q: query).and_return(response)

      subject.run
    end

    context "when 'sort' is set" do
      let(:sort) { "DESC" }
      before(:each) { subject.sort = sort }

      it "sends a get request to the connection with a query parameter for 'set'" do
        connection.should_receive(:get).with("search/#{index}", q: query, sort: sort).and_return(response)

        subject.run
      end
    end

    context "when 'start' is set" do
      let(:start) { 1 }
      before(:each) { subject.start = start }

      it "sends a get request to the connection with a query parameter for 'start'" do
        connection.should_receive(:get).with("search/#{index}", q: query, start: start).and_return(response)

        subject.run
      end
    end

    context "when 'rows' is set" do
      let(:rows) { 1 }
      before(:each) { subject.rows = rows }

      it "sends a get request to the connection with a query parameter for 'rows'" do
        connection.should_receive(:get).with("search/#{index}", q: query, rows: rows).and_return(response)

        subject.run
      end
    end
  end
end
