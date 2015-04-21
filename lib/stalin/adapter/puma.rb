module Stalin::Adapter
  # A Stalin adapter that is suitable for use in Puma worker processes. Puma uses SIGTERM
  # to initiate orderly shutdown and seems to respond to SIGQUIT with an abrupt shutdown.
  class Puma < Rack
    # Create a middleware instance.
    #
    # @param [#call] app inner Rack application
    # @param [Integer] min lower-bound worker memory consumption before restart
    # @param [Integer] max upper-bound worker memory consumption before restart
    # @param [Integer] cycle how frequently to check memory consumption (# requests)
    # @param [Boolean] verbose log extra information
    def initialize(app, min=1024**3, max=2*1024**3, cycle=16, verbose=false)
      require 'puma/cli'
      cli = nil
      ObjectSpace.each_object(::Puma::CLI) { |o| cli = o }

      raise RuntimeError, "Puma does not appear to be active; no instances of Puma::CLI reside in memory" unless cli

      if cli.clustered? && cli.options[:workers] > 0
        # We're clustered, so workers can SIGTERM themselves to cause a restart
        super(app, :TERM, :QUIT, min, max, cycle, verbose)
      else
        # We're running in single mode; our one-and-only process must USR2 to restart
        # itself
        super(app, :USR2, :USR1, min, max, cycle, verbose)
      end
    rescue LoadError => e
      raise RuntimeError, "Puma gem is not available; please add 'puma' to your Gemfile or use another Stalin adapter."
    end
  end
end
