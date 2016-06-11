#!/usr/bin/env ruby
#
# ShortBus example passing return values via Message object

require 'short_bus'

driver = ShortBus::Driver.new

def house_cleaner(message)
  puts 'Lets blow this popsicle stand...'
  sleep 0.5

  # Send value back into the Message object
  message << 'I\'m working on it!'

  # pause
  sleep 1

  # and exit the program
  exit
end

driver.subscribe(
  message_spec: '*::Shutdown',
  service: method(:house_cleaner)
)

# driver.publish returns the message object we just sent
our_message = driver.publish('Everyone::Shutdown')

# Since it is inherited from a Queue, we can pop right off it
return_value = our_message.shift

# And see what the callback wanted to tell us!
puts "I heard back from the house_cleaner, who says: #{return_value}"

# sleep indefinitely, or until we somehow exit...
sleep
