couch-gateway
==============

couch-gateway is an attempt to provide an asynchronous, persistent message gateway to other blocking and potentially slow services. Using Ruby's EventMachine and CouchDB, couch-gateway offers a REST interface for posting messages that are stored and forwarded asynchronously to a third-party system. While not an especially complete solution, hopefully the code can be useful for these sorts of purposes. Have a browse of the code, or if you'd like to know more about how it works, [read on](http://tramperone.posterous.com/couch-gateway-how-it-works)!
