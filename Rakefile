require "rubygems"
require "rake"
require 'couchrest'

namespace :couch do

  DB_URL = "http://127.0.0.1:5984/messages"

  desc "Start CouchDB"
  task :start do
    sh '/Applications/CouchDBX.app/Contents/MacOS/CouchDBX &'
  end

  desc "Recreate messages database"
  task :prepare => [:drop, :create]

  desc "Create messages database"
  task :create do
    db = CouchRest.database!(DB_URL)
    db.save_doc(JSON.parse(File.read("config/design.json")))
  end

  desc "Drop messages database"
  task :drop do
    CouchRest.database(DB_URL).delete! rescue nil
  end

end

namespace :gateway do

  desc "Insert seed messages"
  task :seed do
    messages = []
    10.times do |i|
      message = {text: "message #{i}", requested_at: Time.now, priority: "medium"}
      messages << message
      sleep 0.1
    end
    CouchRest.database(DB_URL).bulk_save(messages)
  end

  desc "Insert a single message"
  task :message do
    CouchRest.database(DB_URL).save_doc({text: "first message", requested_at: Time.now, priority: "medium"})
  end

  desc "Start notification listener"
  task :listen do
    sh 'ruby lib/gateway/listener.rb'
  end

  namespace :examples do

    desc "Start dummy slow server"
    task "slow" do
      sh "ruby examples/slow_server.rb"
    end

  end

end
