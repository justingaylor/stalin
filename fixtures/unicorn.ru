require 'sinatra'
require 'stalin'

min   = Stalin::Watcher.new(Process.pid).watch
max   = Integer(min * 1.10)
delta = (max - min) # guaranteed to hit max after the first request

puts min
puts max
puts delta

leak = ''

get '/' do
  leak << ('L' * delta)
  'Leaked %d bytes; total is now %d bytes' % [delta, leak.length]
end

use Stalin::Adapter::Rack, min, max, 1, true

run Sinatra::Application
