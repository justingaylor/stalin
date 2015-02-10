require 'sinatra'
require 'stalin'

$leak = ''

get '/' do
  $leak << 'Leak' * 640 * (1024*1024) # 640 kb ought to be enough for anybody...
  'Hello world!'
end

use Stalin::Adapter::Unicorn, 1024**2 / 2, 1024**2, 1, true

run Sinatra::Application
