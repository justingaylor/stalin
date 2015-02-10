module Stalin::Watcher
  # Watcher that uses procfs (specifically /proc/<pid>/statm) to determine memory usage.
  class LinuxProcStatm
    # @raise [Stalin::Unsupported] if watcher cannot be instantiated on current platform
    # @param [Integer] pid target process ID
    def initialize(pid)
      @statm = "/proc/%d/statm" % [pid]
      raise Stalin::Unsupported, "Unreadable or nonexistent file: #{@statm}" unless File.readable?(@statm)

      page_size = `getconf PAGESIZE`
      @page_size = Integer(page_size) rescue nil
      raise Stalin::Unsupported, "Cannot determine page size: #{page_size}" unless $?.success? && @page_size.kind_of?(Integer)
    end

    # Report on memory usage.
    #
    # @return [Integer,nil] target process' memory usage in bytes, nil if process not found
    def watch
      vsz, rss, shared = File.read(@statm).split(' ')
      vsz              = Integer(vsz) * @page_size
      rss              = Integer(rss) * @page_size
      shared           = Integer(shared) * @page_size

      rss
    rescue SystemCallError
      # assume any failure means that process has gone away
      nil
    end
  end
end
