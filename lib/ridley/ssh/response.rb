module Ridley
  class SSH
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Response < Struct.new(:stdout, :stderr, :exit_code, :exit_signal); end
  end
end
