# HTTP Proxyable config

# http hosts we allow proxying to.
config['hosts'] = [
  # allow all rubygems.org domains
  /.*(\.|)rubygems.org$/i,
]

# default location to proxy to
config['default_host'] = {
  host: '0.0.0.0',
  port: 80,
}
