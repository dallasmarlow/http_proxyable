#!/usr/bin/env ruby
%w[goliath em-http em-synchrony/em-http].each {|l| require l}

class HttpProxyable < Goliath::API
  use Goliath::Rack::Params

  def on_headers env, headers
    # store request headers for reuse.
    env['client-headers'] = headers
  end

  def response env
    # determine remote target host.
    host = case
    when env.hosts.any? {|host| env['HTTP_HOST'] =~ host}
      env['HTTP_HOST']
    else
      [env.default_host[:host], env.default_host[:port]].join ':'
    end
  
    # setup request
    request = EM::HttpRequest.new ['http://', host, env['REQUEST_PATH']].join
    params  = {:head => env['client-headers'], :query => env.params}
    
    # proxy the request
    response = case env['REQUEST_METHOD']
      when 'HEAD'
        request.head params
      when 'GET'
        request.get params
      when 'POST'
        request.post params.merge(:body => env[Goliath::Request::RACK_INPUT].read)
      else
        env.logger.info ['bad request type', env['REQUEST_METHOD']].join ' : '
    end

    response.errback do
      raise 'failed request to host: ' + host
    end
    
    # parse and prepare repsonse headers
    response_headers = {}
    response.response_header.each_pair do |header, value|
      # rewrite our response headers to be valid
      header = header.downcase.split('_').collect {|h| h.capitalize}.join '-'
      response_headers[header] = value
    end
    [response.response_header.status, response_headers, response.response]
  end
end
