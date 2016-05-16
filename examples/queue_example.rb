#!/usr/bin/env ruby
#
# Nanoservice example using a passed Queue to communicate a return value

require_relative '../nanoservice'

dispatcher = Nanoservice::Dispatcher.new

def house_cleaner(event, payload, queue)
  puts "Lets blow this popsicle stand..." 
  sleep 1
  queue << "I'm working on it!"
  sleep 2
  exit
end
dispatcher.register(event_spec: '*::Shutdown', service: method(:house_cleaner))

return_notice = dispatcher.send('Everyone::Shutdown').shift
puts "I heard back from the house_cleaner, who says: #{return_notice}"

# sleep indefinitely, or until we somehow exit...
sleep
