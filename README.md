# NanoSOA
Simple multithreaded nanoservice framework for Ruby apps

## What is a nanoservice?
Hyperbole.  If a microservice uses language independent messaging and stand-alone services, then a nanoservice is an order of magnitude simpler.

## So what does it do?
Makes it simple to write multithreaded, event-driven Ruby apps with an internal Service Oriented Architecture.

## What are the components?
A Service is an object which participates in the SOA.  It could be a Proc/Block or Method launched on demand to receive, process and optionally send messages, it could have dedicated threads sending messages, or both.  Usually, each Service exists in it's own Module and Class namespace (see examples).  Ideally, the only communication different Services have with eachother is through the Dispatcher.

A Message is what is received, routed and sent to the recipient Services.  A Message is a simple hash composed of an event (a description of the message), and an optional payload object.
```Message = { event: 'example::event', payload: any_object }```

NanoSOA::Dispatcher is the brains of the operation.  Once instantiated, a dedicated thread monitors the message queue and routes the messages to the appropriate recipient Service(s) based on the EventSpec supplied by the Service upon registering with the Dispatcher.

## What does an Event and an EventSpec look like?
An Event is a string.  In it's simplest form, an entire Event (and Message even) can be composed of a simple string, such as 'shutdown', although typically a more descriptive syntax is used which seperates component fields of the Event with ::'s, like 'OwnerService::Action::Detail'.  When a Service registers with the Dispatcher, one or more EventSpecs are supplied, which are used to filter which Events are received.  EventSpecs can be a simple string (like: 'shutdown'), a string including wildcards (like 'OwnerService::*::*', or the equivalent 'OwnerService::**'), a Regexp, or an Array/Set of any of those types.

## So how do you register a Service?
Easy - by calling the NanoSOA::Dispatcher::register method.  Here's a few self-explanatory examples:

```ruby
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

# Instantiate a new object, allow it to process 5 messages simultaneously.
# This Class will need to be written to appropriately handle multiple Threads.
dispatcher.register(
  event_spec: ['*::Commands::Shut*', '*::Commands::Stop*'],
  service: SomeModule::Cleaner.new.message_handler,
  thread_count: 5
)

dispatcher << 'Joe::GoodMessage::hi, bob'

dispatcher.send 'Random Event'

dispatcher << { event: 'Steve::GoodMessage::Your Uncle', payload: 'your_uncle' }

sleep
```
