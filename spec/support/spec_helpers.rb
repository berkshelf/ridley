module Ridley
  module SpecHelpers
    def app_root_path
      Pathname.new(File.expand_path('../../../', __FILE__))
    end

    def fixtures_path
      app_root_path.join('spec/fixtures')
    end
  end
end
