require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'json'

class Handler  < EventMachine::Connection
  include EventMachine::HttpServer

  WAIT_PERIOD = 3

  def process_http_request
    puts "#{@http_request_method}: #{@http_request_uri} body: #{@http_post_content}"
    resp = EventMachine::DelegatedHttpResponse.new( self )

    # Block which fulfills the request
    operation = proc do
      sleep WAIT_PERIOD # simulate a long running request
      resp.content_type 'application/json'
      resp.status = 200
      resp.content = {result: "completed", time_to_complete: "#{WAIT_PERIOD} seconds"}.to_json
    end

    callback = lambda { |res| resp.send_response }
    EM.defer(operation, callback)
  end
end

EventMachine::run {
  EventMachine.epoll
  EventMachine::start_server("0.0.0.0", 8080, Handler)
  puts "Listening..."
}
