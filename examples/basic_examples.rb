#!/usr/bin/env ruby
# 
# Basic usage examples

require_relative '../short_bus'

# Instantiate our Driver and begin our monitoring thread.
driver = ShortBus::Driver.new

# Register a Lambda service.  Default message_spec receives all messages.
driver.subscribe lambda { |message| puts "Event Watcher lambda: #{message}" }

# Usually, you'll supply an message_spec so you don't process unnecessary messages.
#   Driver can also take blocks.  If the Lambda/Block/Method takes two
#   arguments, the second is the message payload, which can be any object that
#   the publisher attaches.
#   
driver.subscribe(message_spec: 'OtherService::Message::*') do |message|
  puts "Block receives only messages matching OtherService::Message::*, like #{message}"
end

# If the return value of the Service hook is a String or a Hash with an :name 
#   key, it will be sent back to the Driver as a new message.  In this case,
#   our Service is a method, which is passed using the #method method.
#
def bob(message)
  puts "Bob got the message #{message}!"
  ["Bob::Reply", "Thanks, I love a good message."]
end

# We'll subscribe with an array of message_specs this time.
driver.subscribe(
  message_spec: ['*::GoodMessage::**', '**::Bob'],
  service: method(:bob)
)

#
# Now, lets try a few messages and see what happens.
#

# In it's simplest form, we'll publish an message with no payload.
driver.publish 'Joe::GoodMessage::hi, bob'

# Now we'll try a Hash, which includes an :name and a :payload.  Also notice
#   we can use the << alias for #publish.
#
driver << { name: 'OtherService::Message::Bob', payload: 'is your uncle' }

# Let the previous message interactions complete.
sleep 0.1

# And bid farewell.
driver << 'Goodbye'

sleep 0.1

# If you run this a few times, you'll see the messages do not print out in the
#   same order.  Welcome to the joys of multi-threaded programming :)  The only
#   guarantee that ShortBus offers is that each Service receives the messages 
#   that meet its message_spec in sequence.
