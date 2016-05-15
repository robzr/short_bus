#!/usr/bin/env ruby

require_relative 'nano_soa'

# Instantiate our Dispatcher and begin our monitoring thread.
dispatcher = NanoSOA::Dispatcher.new(options: { debug: false })

# Easiest way to register a service.  Default EventSpec receives all messages.
dispatcher.register(
  service: lambda { |event, payload| 
    puts "Lambda sez I receive *ALL* events, like this one: #{event}" 
  }
)

# Usually, you'll want to supply an EventSpec.
dispatcher.register(event_spec: 'OtherService::Message::*') do |event, payload|
  puts "I received only events from OtherService"
end

# If the return value of the Service hook is a String or a Hash with
# an :event key, it will be sent back to the Dispatcher as a new message.
def bob(event, payload)
  puts "Bob is running!"
  { event: "Bob::Reply", payload: "Hi, I love a good message." }
end
dispatcher.register(service: method(:bob), event_spec: '*::GoodMessage::**')

dispatcher << 'Joe::GoodMessage::hi, bob'

dispatcher.send 'Random Event'

dispatcher << { event: 'Steve::GoodMessage::Your Uncle', payload: 'your_uncle' }

sleep
