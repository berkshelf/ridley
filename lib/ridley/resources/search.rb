module Ridley
  class Search
    class << self
      # Returns an array of possible search indexes to be search on
      #
      # @param [Ridley::Client] client
      #
      # @example
      #
      #   Search.indexes(client) => [ :client, :environment, :node, :role ]
      #
      # @return [Array<String, Symbol>]
      def indexes(client)
        client.connection.get("search").body.collect { |name, _| name }
      end
    end

    # @return [Ridley::Client]
    attr_reader :client
    attr_reader :index
    attr_reader :query
    
    attr_accessor :sort
    attr_accessor :rows
    attr_accessor :start

    # @param [Ridley::Client] client
    # @param [#to_sym] index
    # @param [#to_s] query
    #
    # @option options [String] :sort
    #   a sort string such as 'name DESC'
    # @option options [Integer] :rows
    #   how many rows to return
    # @option options [Integer] :start
    #   the result number to start from
    def initialize(client, index, query, options = {})
      @client = client
      @index  = index.to_sym
      @query  = query
      @sort   = options[:sort]
      @rows   = options[:rows]
      @start  = options[:start]
    end

    # Executes the built up query on the search's client
    #
    # @example
    #   Search.new(client, :role)
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
      response = client.connection.get(query_uri, query_options).body

      case index
      when :node
        response[:rows].collect { |row| Ridley::NodeResource.new(client, row) }
      when :role
        response[:rows].collect { |row| Ridley::RoleResource.new(client, row) }
      when :client
        response[:rows].collect { |row| Ridley::ClientResource.new(client, row) }
      when :environment
        response[:rows].collect { |row| Ridley::EnvironmentResource.new(client, row) }
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
          options[:q]     = self.query unless self.query.nil?
          options[:sort]  = self.sort unless self.sort.nil?
          options[:rows]  = self.rows unless self.rows.nil?
          options[:start] = self.start unless self.start.nil?
        end
      end
    end
end
