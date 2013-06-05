module Ridley
  class EnvironmentResource < Ridley::Resource
    set_resource_path "environments"
    represented_by Ridley::EnvironmentObject

    # Used to return a hash of the cookbooks and cookbook versions (including all dependencies)
    # that are required by the run_list array.
    #
    # @param [String] environment
    #   name of the environment to run against
    # @param [Array] run_list
    #   an array of cookbooks to satisfy
    #
    # @raise [Errors::ResourceNotFound] if the given environment is not found
    #
    # @return [Hash]
    def cookbook_versions(environment, run_list = [])
      run_list = Array(run_list).flatten
      chef_id  = environment.respond_to?(:chef_id) ? environment.chef_id : environment
      request(:post, "#{self.class.resource_path}/#{chef_id}/cookbook_versions", JSON.fast_generate(run_list: run_list))
    rescue AbortError => ex
      if ex.cause.is_a?(Errors::HTTPNotFound)
        abort Errors::ResourceNotFound.new(ex)
      end
      abort(ex.cause)
    end

    # Delete all of the environments on the client. The '_default' environment
    # will never be deleted.
    #
    # @return [Array<Ridley::EnvironmentObject>]
    def delete_all
      envs = all.reject { |env| env.name.to_s == '_default' }
      envs.collect { |resource| future(:delete, resource) }.map(&:value)
    end
  end
end
