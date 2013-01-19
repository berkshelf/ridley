require 'rubygems'
require 'bundler'
require 'chozo'

def setup_rspec
  require 'rspec'
  require 'json_spec'
  require 'webmock/rspec'

  Dir[File.join(File.expand_path("../../spec/support/**/*.rb", __FILE__))].each { |f| require f }

  RSpec.configure do |config|
    config.include Ridley::SpecHelpers
    config.include JsonSpec::Helpers

    config.mock_with :rspec
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.filter_run focus: true
    config.run_all_when_everything_filtered = true

    config.before(:all) do
      Ridley.logger = nil
      Celluloid.logger = nil
    end

    config.before(:each) do
      clean_tmp_path
    end
  end
end

if mri? && ENV['CI'] != 'true'
  require 'spork'

  Spork.prefork do
    setup_rspec
  end

  Spork.each_run do
    require 'ridley'
  end
else
  require 'ridley'
  setup_rspec
end
