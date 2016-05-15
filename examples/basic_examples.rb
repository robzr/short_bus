#!/usr/bin/env ruby

require_relative '../nanoservice'

# Instantiate our Dispatcher and begin our monitoring thread.
#
dispatcher = Nanoservice::Dispatcher.new(options: { debug: false })


# Register a  to register a service.  Default EventSpec receives all messages.
#
dispatcher.register lambda { |event, payload| 
  puts "Lambda sez I receive *ALL* events, like this one: #{event}" 
}

# Usually, you'll supply an EventSpec so you don't process unnecessary messages.
#
dispatcher.register(event_spec: 'OtherService::Message::*') do |event, payload|
  puts "This block received only events from OtherService, like #{event}"
end

# If the return value of the Service hook is a String or a Hash with an :event 
#   key, it will be sent back to the Dispatcher as a new message.
#
def bob(event, payload)
  puts "Bob got the event #{event}!"
  { event: "Bob::Reply", payload: "Thanks, I love a good message." }
end

dispatcher.register(
  service: method(:bob),
  event_spec: ['*::GoodMessage::**', '**::Bob']
)

# Now, lets try a few messages and see what happens.
#
dispatcher << 'Joe::GoodMessage::hi, bob'

dispatcher << { event: 'OtherService::Message::Bob', payload: 'is your uncle' }

sleep 0.1

dispatcher.send 'Goodbye'

sleep 0.5
