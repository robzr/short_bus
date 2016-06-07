#!/usr/bin/env ruby

# ShortBus example using a passed Queue to communicate a return value

require_relative '../short_bus'

driver = ShortBus::Driver.new

def house_cleaner(message)
  puts "Lets blow this popsicle stand..." 
  sleep 1
  message << "I'm working on it!"
  sleep 2
  exit
end
driver.register(
  event_spec: '*::Shutdown',
  service: method(:house_cleaner)
)

return_message = driver.send('Everyone::Shutdown').shift
puts "I heard back from the house_cleaner, who says: #{return_message}"

# sleep indefinitely, or until we somehow exit...
sleep
