# ShortBus
Multi-threaded pub-sub message dispatcher for implementing self-contained service-oriented Ruby apps.

## What does it do?
The goal is to provide a minimal, lightweight message dispatcher/service API, providing multithreaded event publishing and subscription for Ruby closures (Lambdas/Blocks/Methods)

- TODO: object instantiation for callback if passed a class (maybe?)
- TODO: consider making a mixin class for easier integration
- TODO: make a Redis connector with JSON and binary-serialized object passing
- TODO: cascade block to Service object to avoid block.to\_proc slowdown

ShortBus has no dependencies outside of the Ruby Core & Standard Libraries, and should work with JRuby (TODO: test).

## What are the components?
A Service is a participant in the SOA (Service Oriented Architecture) for sending and/or receiving events. Sending events can be done with the Driver#send method; the return value of this is the Message object, which can then be read as a Queue for a return code.  To receive messages (subscribe), the Service must be registered with the Driver; and is run as a callback in (one or more) dedicated thread(s). The return value from a Service callback will be sent back to the Driver as a new message (if it is of the right type), so be mindful of your return values.

A Message object is what is received, routed and sent to the recipient Services by the Driver. A Message is is composed of an event and an optional payload. Recipients of a message can also return values back to the sender via the Message, as it is an inherited Queue.

The Driver (ShortBus::Driver) is the brains of the operation. Once instantiated, a dedicated thread monitors the message queue and routes the messages to the appropriate recipient Service thread(s) based on the event\_spec(s) supplied by the Service when it registered with the Driver.

## What does an event and an event\_spec look like?
An event is just a String. In it's simplest form, an entire event can be a simple String like `'shutdown'`, but typically a more descriptive form is used which seperates component fields of the event with `::`s, like `'OwnerService::Action::Argument::AnotherArgument'`.

An event\_spec can be supplied by the Service when registering with the Driver, in order to select which events are received by the Service. event\_specs can be a simple String (like: `'shutdown'`), a String including wildcards (`'OwnerService::**'`), a Regexp, or even an Array or Set of multiple Strings and/or Regexps.

### Whats up with those wildcards?
To simplify filtering, a EventSpec String can contain a `*` or a `**` wildcard. A `*` wildcard matches just one field between `::` delimiters. A `**` wildcard matches one or more.

`'Service::*'` matches `'Service::Start'`, but not `'Service::Start::Now'`

`'Service::**'` matches both `'Service::Start'` and `'Service::Start::Now'`

Strings with wildcards are turned into Regexps by the Driver. Wildcard Strings are just a little shorter and more readable.

## Message return values (or, Message as a Queue)
Typically speaking, Services participating in a SOA don't get immediate return values, since an SOA is asynchronous. But since ShortBus generally runs as a single "monolitic" application, we can cheat a bit for convenience, and pass return values back through the Message object.

When a sender publishes a new Message, the return value is the Message itself, which is an inherited Queue. So the sender can then pop() from the Message, which will block and wait for one of the recipients to push() a "return value" into the Message on the other side. To make things more flexible, you can pass pop() (or shift, deq) a numeric value, which acts as a timeout in seconds.

If you don't want to use the Message return value functionality, you can ignore it, and Ruby's garbage collection will destroy the Message automatically.

## How do you use it?
It's easy. Here's a self-explanatory example of a few Services that interact with each other.

```ruby
require_relative 'short_bus'

# First, instantiate the Driver and begin our monitoring thread.
driver = ShortBus::Driver.new

# Now let's register a simple service. All messages are received by default.
driver.register lambda { |message|
  puts "This lambda receives ALL events, like this one: #{message}"
}

# Usually, you'll want to supply an EventSpec when registering the service. You
#   can also register a Block.  Upon finishing, we'll send a new message back to
#   the Driver.
#
driver.register(event_spec: 'OtherService::**') do |message|
  puts "I receive only events from OtherService, like: #{message}"
  'ExampleBlock::ReturnValue::Hi Guys'
end

# Or, you can register a Method.  If the return value of any Service callback is
#   a String or a Hash with an :event key, it will be sent back to the Driver as
#   a new message.
#
def bob(message)
  puts "Bob likes a good message, like: #{message}"
  { event: "Bob::Reply", payload: "Hi, I love a good message." }
end
driver.register(service: method(:bob), event_spec: '*::GoodMessage::**')

# Here's a more complex (and typical) example.  We'll instantiate a new object
#   allow it to process up to 5 messages simultaneously. This Class will need to
#   be written to appropriately handle multiple threads.
#
some_cleaner = SomeModule::Cleaner.new
driver.register(
  event_spec: ['*::Commands::Shut*', '*::Commands::Stop*'],
  service: some_cleaner.method(:message_handler),
  thread_count: 5
)

# Now, send a simple message to the Driver
driver.send 'Random Event'

# << is an alias for send
driver << 'Joe::GoodMessage::hi, bob'

# Or, attach a payload object
driver.send('Steve::GoodMessage::Your Uncle', payload_object)

# Passing a labeled hash makes things a bit easier to read
driver << { 
  event: 'Steve::GoodMessage::Your Uncle',
  payload: payload_object
}

# Or you can declare a Message object and send that manually
new_message = ShortBus::Message.new(
  event: 'Steve::GoodMessage::Your Uncle',
  payload: 'your_uncle',
  sender: 'KindOfAnonymous::Sender'
)
driver << new_message

# We didn't talk about sender:'s, but they follow the same format as events,
#   and can also be key'd on during registration with a sender_spec just like
#   event_spec. Unlike an event however, the sender is automatically populated
#   when a registered service sends a message to the Driver via a return value,
#   and is used internally by the Driver to prevent an infinite loop of a
#   service receiving the message it just sent.

# Finally, to read a return value from the passed Message Queue, just pop it off
#   the return value from #send.
#
unless driver.send('Controller::Shutdown::Gracefully').shift(5)
  puts "I don't think anyone received our message..."
end

# Sleep indefinitely, and let the Services do their work.
sleep
```
