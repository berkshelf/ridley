module Ridley
  class Search
    class << self
      # Returns an array of possible search indexes to be search on
      #
      # @param [Ridley::Connection]
      #
      # @return [Array<String, Symbol]
      def indexes(connection)
        connection.get("search").body.collect { |name, _| name }
      end
    end

    attr_reader :connection
    attr_reader :index
    attr_reader :query
    
    attr_accessor :sort
    attr_accessor :rows
    attr_accessor :start

    def initialize(connection, index, query, options = {})
      @connection = connection
      @index      = index
      @query      = query

      @sort       = options[:sort]
      @rows       = options[:rows]
      @start      = options[:start]
    end

    # Executes the built up query on the search's connection
    #
    # @example
    #   Search.new(connection, :role)
    #   search.run => 
    #     {
    #       total: 1,
    #       start: 0,
    #       rows: [
    #         {
    #           name: "ridley-test-role",
    #           default_attributes: {},
    #           json_class: "Chef::Role",
    #           env_run_lists: {},
    #           run_list: [],
    #           description: "a test role for Ridley!",
    #           chef_type: "role",
    #           override_attributes: {}
    #         }
    #       ]
    #     }
    #
    # @return [Hash]
    def run
      connection.get(query_uri, query_options).body
    end

    private

      def query_uri
        File.join("search", self.index.to_s)
      end

      def query_options
        {}.tap do |options|
          options[:q] = self.query unless self.query.nil?
          options[:sort] = self.sort unless self.sort.nil?
          options[:rows] = self.rows unless self.rows.nil?
          options[:start] = self.start unless self.start.nil?
        end
      end
    end

  module DSL
    # Creates an runs a new Ridley::Search
    #
    # @see Ridley::Search#run
    #
    # @param [String, Symbol] index
    # @param [String, nil] query
    #
    # @option options [String] :sort
    # @option options [Integer] :rows
    # @option options [Integer] :start
    #
    # @return [Hash]
    def search(index, query = nil, options = {})
      Search.new(self, index, query, options).run
    end

    # Return the array of all possible search indexes for the including connection
    #
    # @example
    #   conn = Ridley.connection(...)
    #   conn.search_indexes => 
    #     [:client, :environment, :node, :role, :"ridley-two", :"ridley-one"]
    #
    # @return [Array<Symbol, String>]
    def search_indexes
      Search.indexes(self)
    end
  end
end
