module Stalin
  module Adapter
    class Rack
      def initialize(app, min=1024**3, max=2*1024**3, cycle=16, verbose=false)
        @app     = app
        @min     = min
        @max     = max
        @cycle   = cycle
        @verbose = verbose
      end

      def call(env)
        result = @app.call(env)

        begin
          @lim     ||= @min + randomize(@max - @min + 1)
          @req     ||= 0
          @req     += 1

          if @req % @cycle == 0
            @req = 0
            @watcher ||= ::Stalin::Watcher.new(Process.pid)
            @killer  ||= ::Stalin::Killer.new(Process.pid)
            if (used = @watcher.watch) > @lim
              puts "#{Process.pid} using #{used}!!!"
              @killer.kill
            else
              puts "#{Process.pid} Soldiering on with #{used}"
            end
          end
        rescue Exception => e
          puts "WTF"
          puts e.class.name
          puts e.message
          puts e.backtrace.first
        end

        result
      end

      private

      def randomize(integer)
        RUBY_VERSION > "1.9" ? Random.rand(integer.abs) : rand(integer)
      end

    end
  end
end
