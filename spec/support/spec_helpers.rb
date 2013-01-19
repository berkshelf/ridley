module Ridley
  module SpecHelpers
    def app_root_path
      Pathname.new(File.expand_path('../../../', __FILE__))
    end

    def clean_tmp_path
      FileUtils.rm_rf(tmp_path)
      FileUtils.mkdir_p(tmp_path)
    end

    def fixtures_path
      app_root_path.join('spec/fixtures')
    end

    def tmp_path
      app_root_path.join('spec/tmp')
    end
  end
end
