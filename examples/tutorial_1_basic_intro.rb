#!/usr/bin/env ruby
#
# First example - basic publishing / subscription
#
require_relative '../short_bus'

# Instantiate Driver, start message routing thread
#
driver = ShortBus::Driver.new

# Subscribes a block to all messages (no filtering)
#
driver.subscribe { |message| puts "1. I like all foods, including #{message}" }

# Subscribes a block with a message_spec filtering only some messages
#   Also, replies back to the driver with a new message.
#
driver.subscribe(message_spec: 'Chocolate::**') do |message|
  puts "2. Did I hear you say Chocolate?  (#{message}). I know what I'm making."
  'Chocolate::And::Strawberries'
end

# Subscribes a block with a message_spec filtering only some messages
#
driver.subscribe(message_spec: '**::Strawberries') do |message|
  puts "3. I only care about Strawberries: #{message}"
  'Strawberries'
end

# First lets just test it with an unrelated message
#
driver.publish 'Cookies::And::Cream'
sleep 0.1
puts

# Now lets try some interaction going between services
#
driver.publish 'Chocolate::Anything'
sleep 0.1
