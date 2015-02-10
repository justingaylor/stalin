# stalin

Given Ruby's proclivity for heap fragmentation, Web application worker processes tend to exhaust
all available memory unless the server is restarted periodically. When all of the workers restart
at once, downtime or bad request throughput may result.

Stalin is a gem that gradually kills your workers before they cause swapping, resulting in better
availability for your application. Its design goals are modularity and compatibility with a range
of platforms and app servers.

Metrics include:
  - Resident Set Size (RSS)

Data sources include:
  - Linux ProcFS
  - Generic ps

Supported app servers include:
  - Rainbows (via Rack middleware + SIGQUIT) 
  - Unicorn (via Rack middleware + SIGQUIT)

(As you can see, we are far short of our _goal_ to support many servers! More to come as needed;
I'm happy to take your contributions.)

# Installation

Just include stalin in your Gemfile.

    gem 'stalin'

# Usage

Add these lines near the top of your `config.ru`

    # Unicorn self-process killer
    require 'stalin'

    # Max memory size (RSS) per worker
    mb = 1024**2
    use Stalin::Adapter::Rack, (192*mb), (256*mb)

# Tuning

TODO

# Special Thanks

- [@kzk](http://github.com/kzk/) for the [unicorn-worker-killer] gem which this is derived from
