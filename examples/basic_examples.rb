#!/usr/bin/env ruby
# 
# Basic usage examples

require_relative '../nanoservice'

# Instantiate our Dispatcher and begin our monitoring thread.
dispatcher = Nanoservice::Dispatcher.new

# Register a Lambda service.  Default EventSpec receives all messages.
dispatcher.register lambda { |message| puts "Event Watcher lambda: #{message.event}" }

# Usually, you'll supply an EventSpec so you don't process unnecessary messages.
#   Dispatcher can also take blocks.  If the Lambda/Block/Method takes two
#   arguments, the second is the message payload, which can be any object that
#   the sender attaches.
#   
dispatcher.register(event_spec: 'OtherService::Message::*') do |message|
  puts "Block receives only events matching OtherService::Message::*, like #{message.event}"
end

# If the return value of the Service hook is a String or a Hash with an :event 
#   key, it will be sent back to the Dispatcher as a new message.  In this case,
#   our Service is a method, which is passed using the #method method.
#
def bob(message)
  puts "Bob got the event #{message.event}!"
  Nanoservice::Message.new("Bob::Reply", "Thanks, I love a good message.")
end

# We'll register with an array of event_specs this time.
dispatcher.register(event_spec: ['*::GoodMessage::**', '**::Bob'],
                    service: method(:bob))

# Now, lets try a few messages and see what happens.

# In it's simplest form, we'll send an event with no payload.
dispatcher.send 'Joe::GoodMessage::hi, bob'

# Now we'll try a Hash, which includes an :event and a :payload.  Also notice
#   we can use the << alias for #send.
#
dispatcher << { event: 'OtherService::Message::Bob', payload: 'is your uncle' }

# Let the previous event interactions complete.
sleep 0.1

# And bid farewell.
dispatcher << 'Goodbye'

sleep 0.1

# If you run this a few times, you'll see the messages do not print out in the
#   same order.  Welcome to the joys of multi-threaded programming :)  The only
#   guarantee that Nanoservice offers is that each Service receives the messages 
#   that meet its EventSpec in sequence.
