module Stalin
  module Adapter
    module Unicorn
      def self.new(app, memory_limit_min = (1024**3), memory_limit_max = (2*(1024**3)), check_cycle = 16, verbose = false)
        raise "blah" unless watcher.watch > 0

        Unicorn::HttpServer.instance_eval do
          include ::Stalin::Adapter::Unicorn
          unless instance_methods.include?(:process_client_with_stalin)
            alias_method :process_client_without_stalin, :process_client
            alias_method :process_client, :process_client_with_stalin
          end
        end

        ObjectSpace.each_object(::Unicorn::HttpServer) do |s|
          s.extend(self)
          s.instance_variable_set(:@_worker_memory_limit_min, memory_limit_min)
          s.instance_variable_set(:@_worker_memory_limit_max, memory_limit_max)
          s.instance_variable_set(:@_worker_check_cycle, check_cycle)
          s.instance_variable_set(:@_worker_check_count, 0)
          s.instance_variable_set(:@_verbose, verbose)
          File.open('/tmp/tony', 'a') { |f| f.puts "#{Process.pid} EXT #{s.object_id}" }
        end

        app # pretend to be Rack middleware
      end

      def randomize(integer)
        RUBY_VERSION > "1.9" ? Random.rand(integer.abs) : rand(integer)
      end

      def process_client_with_stalin(client)
        File.open('/tmp/tony', 'a') { |f| f.puts "#{Process.pid} CYC=#{@_worker_check_count}/#{@_worker_check_cycle}" }
        super(client) # Unicorn::HttpServer#process_client
        return if @_worker_memory_limit_min == 0 && @_worker_memory_limit_max == 0

        @_worker_process_start ||= Time.now
        @_worker_memory_limit ||= @_worker_memory_limit_min + randomize(@_worker_memory_limit_max - @_worker_memory_limit_min + 1)
        @_worker_check_count += 1
        if @_worker_check_count % @_worker_check_cycle == 0
          @_watcher ||= Stalin::Watcher.new(Process.pid)
          @_killer ||= Stalin::Killer.new(Process.pid)
          rss = @_watcher.watch
          File.open('/tmp/tony', 'a') { |f| f.puts "#{Process.pid} RSS=#{rss}" }
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
