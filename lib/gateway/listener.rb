require 'em-http'
require 'json'
require 'couchrest'
require 'fiber'

module Gateway

  class Listener

    DB_URL = "http://localhost:5984/messages"
    TARGET_URL = "http://localhost:8080"
    HEARTBEAT = /^\n/

    def initialize
      @db = CouchRest.database(DB_URL)
    end

    def run(update_seq = 0)
      log "Listener running..."
      EventMachine.run {
        opts = { query: {feed: 'continuous', since: update_seq, heartbeat: 5000, filter: 'app/pending', include_docs: true} }
        http = EventMachine::HttpRequest.new("#{DB_URL}/_changes").get opts
        http.stream { |chunk| handle_notification(chunk) unless chunk =~ HEARTBEAT  }
      }
    end

    def catchup
      update_sequence = @db.info["update_seq"]
      unprocessed = @db.view('app/unprocessed')['rows']
      update_all_as_missed(unprocessed)
      update_sequence
    end

    private

def handle_notification(notification)
  log "got notification: #{notification}"
  message = JSON.parse(notification)['doc']
  Fiber.new {
    result = despatch(message) # non-blocking
    @db.save_doc(message.merge(status: "forwarded", result: result))  # blocking
  }.resume
end

def despatch(message)
  http = http_request({id: message['_id'], broadcast: message['text']})
  http.response_header.status == 200 ? "success" : "failed"
end

def http_request(data = {})
  f = Fiber.current
  http = EventMachine::HttpRequest.new(TARGET_URL).post :body => data
  http.callback { log "Http request: #{http.response_header.status}"; f.resume(http) }
  http.errback  { log "Http request error: #{data}"; f.resume(http) }
  return Fiber.yield
end

      def update_all_as_missed(messages)
        log "Found #{messages.size} missed messages"
        log "updating statuses..." unless messages.empty?
        messages.each do |message|
          doc = @db.get(message["id"])
          @db.save_doc(doc.merge(status: "missed"))
        end
      end

      def log(message)
        puts "****#{message}"
      end

  end

end

if __FILE__ == $0
  listener = Gateway::Listener.new
  seq = listener.catchup
  sleep 1 # let missed messages get updated
  listener.run(seq)
end
