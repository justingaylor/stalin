module Stalin
  # Exception that watchers raise when they are not supported on the current platform.
  class Unsupported < NotImplementedError
  end

end

require 'stalin/killer'
require 'stalin/watcher'
require 'stalin/adapter'
