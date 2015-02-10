module Stalin::Watcher
  class UnixPs
    # @raise [Stalin::Unsupported] if watcher cannot be instantiated on current platform
    # @param [Integer] pid target process ID
    def initialize(pid)
      begin
        ps(Process.pid)
      rescue StandardError => e
        raise Stalin::Unsupported, "ps failed: #{e.message}"
      end

      @pid = pid
    end

    # Report on memory usage.
    #
    # @return [Integer,nil] target process' memory usage in bytes, nil if process not found
    def watch
      ps(@pid)
    rescue ArgumentError
      nil
    end

    private

    # Report on memory usage.
    #
    # @return [Integer] target process' memory usage in bytes
    def ps(pid)
      Integer(`#{"ps -o rss= -p %d" % [pid]}`) * 1024
    end
  end
end
