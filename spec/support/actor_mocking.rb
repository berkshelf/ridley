RSpec.configuration.before(:each) do
  class Celluloid::CellProxy
    unless @rspec_compatible
      @rspec_compatible = true
      undef_method :should_receive if method_defined?(:should_receive)
      undef_method :stub if method_defined?(:stub)
    end
  end
end
