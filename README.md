# ShortBus
Easy to use multi-threaded pub-sub message dispatcher for implementing self-contained service-oriented Ruby apps.

## What does it do?
The goal is to provide a minimal, lightweight message dispatcher/service API, with multi-threaded message publishing and subscription for Ruby closures (Lambdas/Blocks) and Methods.

ShortBus has no dependencies outside of the Ruby Core & Standard Libraries.

## What are the components?
A service is a participant in the SOA (Service Oriented Architecture) for publishing and/or subscribing to messages. To receive messages, the service subscribes to the Driver (Driver#subscribe); and is run as a callback in a dedicated thread or thread pool.

A message (as simple as a String, but ultimately converted to a ShortBus::Message object) is what is received, routed and sent to the recipient services by the Driver. A message can have an optional payload object, and subscribers can return values directly back to the publisher by using the Message object as a Queue (see "Message return values" below).

The Driver (ShortBus::Driver) is the brains of the operation. Once instantiated, a dedicated thread monitors the incoming queue, converts and routes the messages to the appropriate subscribers based on the message\_spec(s) supplied at the time of subscription.

## What does a message and a message\_spec look like?
In it's simplest form, a message can be a simple String like `'shutdown'`, but typically a more flexible, component based format is used, delimited by `::`, like `'OwnerService::Action::Argument'`.  The Driver will convert the message String into a ShortBus::Message object before routing.

A message\_spec can be supplied by the service when subscribing in order to select which messages are received by the service. A message\_spec can be a String (`'shutdown'`), a String with wildcards (`'OwnerService::**'`), a Regexp, or even an Array or Set of multiple Strings and/or Regexps.

### Whats up with those wildcard Strings?
To simplify filtering, a message\_spec String can contain a `*` or a `**` wildcard. A `*` wildcard matches just one field between `::` delimiters. A `**` wildcard matches one or more.

`'Service::*'` matches `'Service::Start'`, but not `'Service::Start::Now'`

`'Service::**'` matches both `'Service::Start'` and `'Service::Start::Now'`

Wilcard Strings are turned into Regexps by the Driver.

## Message return values (Message as a Queue)
Typically speaking, services participating in a SOA do not get immediate return values, as an SOA is asynchronous. Since ShortBus generally runs as a monolithic application, we can cheat a bit for convenience, and pass return values back through the Message object (which is an inherited Queue class).

When a new Message is published via the Driver#publish method, the return value is the same Message object that subscribers receive.

The publisher can then #pop from that Message, which will block and wait for one of the subscribers to #push a "return value" into the Message on the other side. To make things more flexible, #pop (and #shift, #deq) has been extended to accept a numeric value, which acts as a timeout in seconds.

If you don't want to use the Message return value functionality, you can ignore it, and Ruby's garbage collection will destroy the Message automatically once all subscriber callbacks have completed.

## How do you use it?
It's easy. Here's a self-explanatory example of a few services that interact with each other.

```ruby
require_relative 'short_bus'

# First, instantiate the Driver and begin our monitoring thread.
driver = ShortBus::Driver.new

# Now let's subscribe a simple service. All messages are received by default.
driver.subscribe lambda { |message|
  puts "This lambda receives ALL message, like this one: #{message}"
}

# Usually, you'll want to supply a message_spec when subscribing. You can also
#  subscribe a Block.  Upon finishing, we'll send a new message back to
#  the Driver.
#
driver.subscribe(message_spec: 'OtherService::**') do |message|
  puts "I receive only messages from OtherService, like: #{message}"
  'ExampleBlock::ReturnValue::Uneccessary Text'
end

# Or, you can subscribe a Method. If the return value of any Service callback is
#   a String, Array or a Hash with an :message key, it will be sent back to the
#   Driver as a new message.
#
def bob(message)
  puts "Bob likes a good message, like: #{message}"
  { message: "Bob::Reply", payload: "Hi, I love a good message." }
end
driver.subscribe(service: method(:bob), message_spec: '*::GoodMessage::**')

# Here's a more complex (and typical) example.  We'll instantiate a new object
#   allow it to process up to 5 messages simultaneously. This Class will need to
#   be written to appropriately handle multiple threads.
#
some_cleaner = SomeModule::Cleaner.new
driver.subscribe(
  message_spec: ['*::Commands::Shut*', '*::Commands::Stop*'],
  service: some_cleaner.method(:message_handler),
  thread_count: 5
)

# Now, send a simple message to the Driver
driver.send 'Random Event'

# << is an alias for send
driver << 'Joe::GoodMessage::hi, bob'

# Or, attach a payload object
driver.send 'Steve::GoodMessage::Your Uncle', payload_object

# Passing a labeled hash makes things a bit easier to read
driver << { 
  message: 'Steve::GoodMessage::Your Uncle',
  payload: payload_object
}

# Or you can declare a Message object and send that manually
new_message = ShortBus::Message.new(
  message: 'Steve::GoodMessage::Your Uncle',
  payload: 'your_uncle',
  publisher: 'KindOfAnonymous::Sender'
)
driver << new_message

# The :publisher attribute follows the same format as a messages, and
#   can also be keyed on during subscription with a publisher_spec,
#   just like message_spec. Unlike a message, the publisher attribute
#   is automatically populated when a subscriber sends a message to 
#   the Driver via a return value. A service automatically has a 
#   publisher name selected, but can also be specified at subscription
#   time with the :name key.

# Finally, to read a return value from the passed Message Queue, just
#   pop it off the return value from #send.
#
unless driver.send('Controller::Shutdown::Gracefully').shift(5)
  puts "I don't think anyone received our message..."
end

# Sleep indefinitely, and let the Services do their work.
sleep
```

## TODO
- class based services (object instantiation on callback)
- mixin class for easier integration
- Redis connector with JSON and binary-serialized object passing
- cascade block to Service object to avoid block.to\_proc slowdown
- document, make gem, publish
