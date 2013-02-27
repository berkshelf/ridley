require 'mixlib/shellout'

module Ridley::Mixin
  # @author Jamie Winsor <jamie@vialstudios.com>
  module ShellOut
    # @return [Mixlib::ShellOut]
    def shell_out(*command_args)
      cmd = Mixlib::ShellOut.new(*command_args)
      if STDOUT.tty?
        cmd.live_stream = STDOUT
      end
      cmd.run_command
      cmd
    end

    # @return [Mixlib::ShellOut]
    def shell_out!(*command_args)
      cmd = shell_out(*command_args)
      cmd.error!
      cmd
    end
  end
end
