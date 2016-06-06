# ShortBus
Multi-threaded message dispatcher for implementing self-contained service-oriented Ruby apps.

## What does it do?
The goal is to provide a minimal, lightweight message dispatcher/service API, providing multithreaded event publishing and subscription for Ruby closures (Lambdas/Blocks/Methods)

- TODO: object instantiation for callback if passed a class (maybe?)
- TODO: consider making a mixin class for easier integration

ShortBus has no dependencies outside of the Ruby Core & Standard Libraries, and should work with JRuby.

## What are the components?
A Service is a participant in the SOA (Service Oriented Architecture) for sending and/or receiving events. To subscribe to events, the Service must be registered with the Driver. No registration is necessary to simply send messages, and even receive responses directly to those messages.

A subscribed Service is a Lambda, Block or Method that is registered as a callback with the Driver, and runs in (one or more) dedicated thread(s). The return value from a Service callback will be sent back to the Driver as a new message (if it is of the right type), so be mindful of  your return values.

A Message is what is received, routed and sent to the recipient Services. A Message is an object which is composed of an Event and an optional payload. Recipients of a message can also return values back to the sender via the Message, as it is an inherited Queue.

The Driver (ShortBus::Driver) is the brains of the operation. Once instantiated, a dedicated thread monitors the message queue and routes the messages to the appropriate recipient Service(s) based on the EventSpec(s) supplied by the Service when it registered with the Driver.

## What does an Event and an EventSpec look like?
An Event is just a String. In it's simplest form, an entire Event can be a simple String like `'shutdown'`, but typically a more descriptive form is used which seperates component fields of the Event with `::`s, like `'OwnerService::Action::Argument::AnotherArgument'`.

An EventSpec can be supplied by the Service when registering with the Driver, in order to select which Events are received by the Service.  EventSpecs can be a simple String (like: `'shutdown'`), a String including wildcards (`'OwnerService::**'`), a Regexp, or even an Array or Set of multiple Strings/Regexps.

### Whats up with those wildcards?
To simplify filtering, a EventSpec String can contain a `*` or a `**` wildcard.  A `*` wildcard matches just one field between `::` delimiters.  A `**` wildcard matches one or more.

`'Service::*'` matches `'Service::Start'`, but not `'Service::Start::Now'`

`'Service::**'` matches both `'Service::Start'` and `'Service::Start::Now'`

Strings with wildcards are turned into Regexps by the Driver.  Wildcard Strings are just a little shorter and more readable.

## Passed Queues (or, what about return values?)
Typically speaking, Services participating in a SOA don't get return values, since an SOA is asynchronous. But since ShortBus general runs as a single App, we can cheat a bit for convenience.

When a sender publishes a new Message, the return value is the Message itself, which is an inherited Queue. So the sender can then pop() from the Message, which will block and wait for one of the recipients to push() a "return value" into the Message on the other side. To make things more flexible, you can pass pop (or shift, deq) a numeric value, which acts as a timeout in seconds.

If you don't want to use the Message return value functionality, you can ignore it, and Ruby's garbage collection will destroy the Message automatically.

## How do you use it?
It's easy.  Here's a self-explanatory example of a few Services that interact with each other.

```ruby
require_relative 'short_bus'

# First, instantiate the Driver and begin our monitoring thread.
driver = ShortBus::Driver.new

# Now let's register a simple service. All messages are received by default.
driver.register lambda { |message|
  puts "This lambda sez I receive *ALL* events, like this one: #{message}"
}

# Usually, you'll want to supply an EventSpec when registering the service. You
#   can also register a Block.  Upon finished, we'll send a new message
#   back to the Driver.
#
driver.register(event_spec: 'OtherService::**') do |message|
  puts "I receive only events from OtherService, like: #{event}"
  'ExampleBlock::ReturnValue::Hi Guys'
end

# Or, you can register a Method.  If the return value of any Service hook is a 
#   String or a Hash with an :event key, it will be sent back to the Driver 
#   as a new message.
#
def bob(message)
  puts "Bob is running because he got the event #{message}"
  { event: "Bob::Reply", payload: "Hi, I love a good message." }
end
driver.register(service: method(:bob), event_spec: '*::GoodMessage::**')

# Here's a more complex (and probably typical) example.  We'll instantiate a new
#   object, allow it to process up to 5 messages simultaneously. This Class will
#   need to be written to appropriately handle multiple threads.
#
driver.register(
  event_spec: ['*::Commands::Shut*', '*::Commands::Stop*'],
  service: SomeModule::Cleaner.new.message_handler,
  thread_count: 5
)

# Now, send a simple message to the Driver
driver.send 'Random Event'

# << is an alias for send
driver << 'Joe::GoodMessage::hi, bob'

# If you want to attach a payload, use a Hash
driver << { event: 'Steve::GoodMessage::Your Uncle', payload: 'your_uncle' }

# Or you can get fancier and declare a Message object
driver << ShortBus::Message.new(
  event: 'Steve::GoodMessage::Your Uncle',
  payload: 'your_uncle',
  sender: 'Anonymous::Sender'
)

# We didn't talk about sender:'s, but they follow the same format as events,
#   and can also be key'd on during registration with a sende\_spec just like
#   event\_spec.  The primary difference is that a sender is automatically
#   populated when a registered service sends a message to the Driver via a
#   return value, and is used to prevent a loop of a service receiving messages
#   it just sent.

# Finally, to read a return value from the passed Message Queue, just pop it
#   off the return value from #send.
#
unless driver.send('Controller::Shutdown::Gracefully').shift(5)
  puts "I don't think anyone received our message..."
end

# Sleep indefinitely, and let the Services do their work.
sleep
```
