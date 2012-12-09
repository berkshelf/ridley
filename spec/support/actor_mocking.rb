RSpec.configuration.before(:each) do
  class Celluloid::ActorProxy
    unless @rspec_compatible
      @rspec_compatible = true
      undef_method :should_receive
      undef_method :stub
    end
  end
end
