module Stalin::Adapter
  # A low-tech but reliable solution that invokes stalin using Rack middleware.
  # This is suitable for servers that handle SIGQUIT gracefully and spawn new
  # worker processes as needed.
  class Rack
    # Conversion constant for human-readable memory amounts in log messages.
    MB = Float(1024**2)

    # Create a middleware instance.
    #
    # @param [#call] app
    # @param [Integer] min lower-bound worker memory consumption before restart
    # @param [Integer] max upper-bound worker memory consumption before restart
    # @param [Integer] cycle how frequently to check memory consumption (# requests)
    # @param [Boolean] verbose log extra information
    def initialize(app, min=1024**3, max=2*1024**3, cycle=16, verbose=false)
      @app     = app
      @min     = min
      @max     = max
      @cycle   = cycle
      @verbose = verbose
    end

    def call(env)
      result = @app.call(env)

      logger = logger_for(env)

      begin
        @lim     ||= @min + randomize(@max - @min + 1)
        @req     ||= 0
        @req     += 1

        if @req % @cycle == 0
          @req = 0
          @watcher ||= ::Stalin::Watcher.new(Process.pid)
          @killer  ||= ::Stalin::Killer.new(Process.pid)
          if (used = @watcher.watch) > @lim
            sig = @killer.kill
            @watcher.watch
            logger.info "stalin (pid: %d) send SIG%s; memory usage %.1f MB > %.1f MB" %
                          [Process.pid, sig, used / MB, @lim / MB]
            @cycle = 2
          elsif @verbose
            logger.info "stalin (pid: %d) soldiers on; memory usage %.1f MB < %.1f MB" %
                           [Process.pid, used / MB, @lim / MB]
          end
        end
      rescue Exception => e
        logger.error "stalin (pid: %d) ERROR %s: %s (%s)" %
                      [Process.pid, e.class.name, e.message, e.backtrace.first]
      end

      result
    end

    private

    def randomize(integer)
      RUBY_VERSION > "1.9" ? Random.rand(integer.abs) : rand(integer)
    end

    def logger_for(env)
      env['rack.logger'] || (@logger ||= Logger.new(STDERR))
    end
  end
end
