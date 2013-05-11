module Ridley
  # @author Jamie Winsor <reset@riotgames.com>
  class SearchResource < Ridley::Resource
    class << self
      # @param [String] query_string
      #
      # @option options [String] :sort
      #   a sort string such as 'name DESC'
      # @option options [Integer] :rows
      #   how many rows to return
      # @option options [Integer] :start
      #   the result number to start from
      #
      # @return [Hash]
      def build_query(query_string, options = {})
        {}.tap do |query_opts|
          query_opts[:q]     = query_string unless query_string.nil?
          query_opts[:sort]  = options[:sort] unless options[:sort].nil?
          query_opts[:rows]  = options[:rows] unless options[:rows].nil?
          query_opts[:start] = options[:start] unless options[:start].nil?
        end
      end

      # @param [#to_s] index
      #
      # @return [String]
      def query_uri(index)
        "#{resource_path}/#{index}"
      end
    end

    set_resource_path "search"

    # Returns an array of possible search indexes to be search on
    #
    # @param [Ridley::Client] client
    #
    # @example
    #
    #   Search.indexes(client) => [ :client, :environment, :node, :role ]
    #
    # @return [Array<String, Symbol>]
    def indexes
      request(:get, self.class.resource_path).collect { |name, _| name }
    end

    # Executes the built up query on the search's client
    #
    # @param [#to_sym, #to_s] index
    # @param [#to_s] query_string
    #
    # @option options [String] :sort
    #   a sort string such as 'name DESC'
    # @option options [Integer] :rows
    #   how many rows to return
    # @option options [Integer] :start
    #   the result number to start from
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
    # @return [Array<ChefObject>, Hash]
    def run(index, query_string, resources_registry, options = {})
      query_uri = self.class.query_uri(index)
      query     = self.class.build_query(query_string, options)
      response  = request(:get, query_uri, query)

      case index.to_sym
      when :node
        response[:rows].collect { |row| Ridley::NodeObject.new(resources_registry[:node_resource], row) }
      when :role
        response[:rows].collect { |row| Ridley::RoleObject.new(resources_registry[:role_resource], row) }
      when :client
        response[:rows].collect { |row| Ridley::ClientObject.new(resources_registry[:client_resource], row) }
      when :environment
        response[:rows].collect { |row| Ridley::EnvironmentObject.new(resources_registry[:environment_resource], row) }
      else
        response[:rows]
      end
    end
  end
end
