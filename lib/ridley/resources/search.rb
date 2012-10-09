module Ridley
  class Search
    class << self
      # Returns an array of possible search indexes to be search on
      #
      # @param [Ridley::Connection] connection
      #
      # @example
      #
      #   Search.indexes(connection) => [ :client, :environment, :node, :role ]
      #
      # @return [Array<String, Symbol>]
      def indexes(connection)
        connection.get("search").body.collect { |name, _| name }
      end
    end

    # @return [Ridley::Connection]
    attr_reader :connection
    attr_reader :index
    attr_reader :query
    
    attr_accessor :sort
    attr_accessor :rows
    attr_accessor :start

    # @param [Ridley::Connection] connection
    # @param [#to_sym] index
    # @param [#to_s] query
    #
    # @option options [String] :sort
    #   a sort string such as 'name DESC'
    # @option options [Integer] :rows
    #   how many rows to return
    # @option options [Integer] :start
    #   the result number to start from
    def initialize(connection, index, query, options = {})
      @connection = connection
      @index      = index.to_sym
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
      response = connection.get(query_uri, query_options).body

      case index
      when :node
        response[:rows].collect { |row| Node.new(connection, row) }
      when :role
        response[:rows].collect { |row| Role.new(connection, row) }
      when :client
        response[:rows].collect { |row| Client.new(connection, row) }
      when :environment
        response[:rows].collect { |row| Environment.new(connection, row) }
      else
        response[:rows]
      end
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
