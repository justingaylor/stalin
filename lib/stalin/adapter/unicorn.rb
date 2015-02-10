module Stalin
  module Adapter
    module Unicorn
      def self.new(app, memory_limit_min = (1024**3), memory_limit_max = (2*(1024**3)), check_cycle = 16, verbose = false)
        watcher = Stalin::Watcher.new(Process.pid)
        killer = Stalin::Killer.new(Process.pid)

        raise "blah" unless watcher.watch > 0

        ObjectSpace.each_object(::Unicorn::HttpServer) do |s|
          s.extend(self)
          s.instance_variable_set(:@_worker_memory_limit_min, memory_limit_min)
          s.instance_variable_set(:@_worker_memory_limit_max, memory_limit_max)
          s.instance_variable_set(:@_worker_check_cycle, check_cycle)
          s.instance_variable_set(:@_worker_check_count, 0)
          s.instance_variable_set(:@_verbose, verbose)
          s.instance_variable_set(:@_watcher, watcher)
          s.instance_variable_set(:@_killer, killer)
        end

        app # pretend to be Rack middleware
      end

      def randomize(integer)
        RUBY_VERSION > "1.9" ? Random.rand(integer.abs) : rand(integer)
      end

      def process_client(client)
        super(client) # Unicorn::HttpServer#process_client
        return if @_worker_memory_limit_min == 0 && @_worker_memory_limit_max == 0

        @_worker_process_start ||= Time.now
        @_worker_memory_limit ||= @_worker_memory_limit_min + randomize(@_worker_memory_limit_max - @_worker_memory_limit_min + 1)
        @_worker_check_count += 1
        if @_worker_check_count % @_worker_check_cycle == 0
          rss = @_watcher.watch
          logger.info "#{self}: worker (pid: #{Process.pid}) using #{rss} bytes." if @_verbose
          if rss.nil?
            logger.warn "#{self}: worker (pid: #{Process.pid}) failed to observe process status"
          elsif rss > @_worker_memory_limit
            logger.warn "#{self}: worker (pid: #{Process.pid}) exceeds memory limit (#{rss} bytes > #{@_worker_memory_limit} bytes)"
            @_killer.kill
          end
          @_worker_check_count = 0
        end
      end
    end
  end
end
