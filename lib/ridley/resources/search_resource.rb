module Ridley
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

      # Builds and returns a query parameter string for the search API
      #
      # @param [String] query_string
      #
      # @option options [String] :sort
      #   a sort string such as 'name DESC'
      # @option options [Integer] :rows
      #   how many rows to return
      # @option options [Integer] :start
      #   the result number to start from
      #
      # @example
      #   build_param_string("*:*", rows: 5) #=> "?q=*:*&rows=5"
      #
      # @return [String]
      def build_param_string(query_string, options = {})
        query = build_query(query_string, options)
        param = "?q=#{escape(query[:q])}"
        param += "&sort=#{escape(query[:sort])}" if query[:sort]
        param += "&start=#{escape(query[:start])}" if query[:start]
        param += "&rows=#{escape(query[:rows])}" if query[:rows]
        param
      end

      # @param [#to_s] index
      #
      # @return [String]
      def query_uri(index)
        "#{resource_path}/#{index}"
      end

      private

        def escape(str)
          str && URI.escape(str.to_s)
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

      handle_response(index, resources_registry, request(:get, query_uri, query))
    end

    # Perform a partial search on the Chef server
    #
    # @param [#to_sym, #to_s] index
    # @param [#to_s] query_string
    # @param [Array] attributes
    #   an array of strings in dotted hash notation representing the attributes to return
    #
    # @option options [String] :sort
    #   a sort string such as 'name DESC'
    # @option options [Integer] :rows
    #   how many rows to return
    # @option options [Integer] :start
    #   the result number to start from
    #
    # @return [Array<ChefObject>, Hash]
    def partial(index, query_string, attributes, resources_registry, options = {})
      query_uri    = self.class.query_uri(index)
      param_string = self.class.build_param_string(query_string, options)
      body         = build_partial_body(index, attributes)

      handle_partial(index, resources_registry, request(:post, "#{query_uri}#{param_string}", JSON.generate(body)))
    end

    private

      def build_partial_body(index, attributes)
        chef_id = chef_id_for_index(index)

        Hash.new.tap do |body|
          body[chef_id] = [ chef_id ] if chef_id

          if index.to_sym == :node
            body['cloud.public_hostname'] = [ 'cloud', 'public_hostname' ]
            body['cloud.public_ip4v']     = [ 'cloud', 'public_ip4v' ]
            body['cloud.provider']        = [ 'cloud', 'provider' ]
            body['fqdn']                  = [ 'fqdn' ]
            body['ipaddress']             = [ 'ipaddress' ]
          end

          attributes.collect { |attr| body[attr] = attr.split('.') }
        end
      end

      def chef_id_for_index(index)
        chef_id = index.to_sym == :node ? Ridley::NodeObject.chef_id : nil
      end

      def handle_partial(index, registry, response)
        chef_id = chef_id_for_index(index)

        case index.to_sym
        when :node
          response[:rows].collect do |item|
            attributes = Hashie::Mash.new
            item[:data].each do |key, value|
              next if key.to_s == chef_id.to_s
              attributes.deep_merge!(Hash.from_dotted_path(key, value))
            end
            registry[:node_resource].new(name: item[:data][chef_id], automatic: attributes)
          end
        else
          response[:rows]
        end
      end

      def handle_response(index, registry, response)
        case index.to_sym
        when :node
          response[:rows].collect { |row| NodeObject.new(registry[:node_resource], row) }
        when :role
          response[:rows].collect { |row| RoleObject.new(registry[:role_resource], row) }
        when :client
          response[:rows].collect { |row| ClientObject.new(registry[:client_resource], row) }
        when :environment
          response[:rows].collect { |row| EnvironmentObject.new(registry[:environment_resource], row) }
        else
          response[:rows]
        end
      end
  end
end
