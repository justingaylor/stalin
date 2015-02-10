module Stalin
  module Watcher
    def self.new(pid)
      it = nil

      constants.each do |konst|
        begin
          konst = const_get(konst)
          it = konst.new(pid)
          break
        rescue Stalin::Unsupported
          next
        end
      end

      it || raise(Stalin::Unsupported, "No compatible Watcher was found among #{constants}")
    end
  end
end

require 'stalin/watcher/linux_proc_statm'
require 'stalin/watcher/unix_ps'
