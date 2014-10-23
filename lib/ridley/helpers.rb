module Ridley
  module Helpers
    def self.options_slice(options, *keys)
      keys.inject({}) do |memo, key|
        memo[key] = options[key] if options.include?(key)
        memo
      end
    end
  end
end
