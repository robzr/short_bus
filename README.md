# nanoservice
Simple multi-threaded nanoservice/SOA (Service Oriented Architecture) framework for Ruby apps.

## What is a nanoservice?
Hyperbole.  If a microservice uses language independent messaging and stand-alone services, then a nanoservice is an order of magnitude simpler. In it's simplest form, a nanoservice is simply a thread launched in response to a subscribed event.

## So what does it do?
Makes it simple to write multi-threaded, event-driven Ruby apps with an internal Service Oriented Architecture.  Nanoservice has no dependencies outside of the Ruby Core & Standard Libraries, and should work with JRuby.

## What are the components?
A Service is an object which participates in the SOA.  It could be a Proc/Block or Method launched on demand to receive, process and optionally send messages, it could have dedicated threads sending messages, or both.  Usually, each Service exists in it's own Module and Class namespace (see examples).  Ideally, the only communication different Services have with each other is through the Dispatcher.

A Message is what is received, routed and sent to the recipient Services.  A Message is a simple hash composed of an event (a description of the message), and an optional payload object.

`Message = { event: 'example::event', payload: any_object }`

The Dispatcher (Nanoservice::Dispatcher) is the brains of the operation.  Once instantiated, a dedicated thread monitors the message queue and routes the messages to the appropriate recipient Service(s) based on the EventSpec(s) supplied by the Service upon registering with the Dispatcher.

## What does an Event and an EventSpec look like?
An Event is just a string.  In it's simplest form, an entire Event (and Message even) can be composed entirely of a simple string like `'shutdown'`, but typically a more descriptive form is used which seperates component fields of the Event with `::`s, like `'OwnerService::Action::Detail'`.

An EventSpec is (optionally) supplied by the Service when registering with the Dispatcher, and is used to filter which Events are received.  EventSpecs can be a simple string (like: `'shutdown'`), a string including wildcards (`'OwnerService::**'`), a Regexp, or even an Array/Set of multiple Strings/Regexps.

### Whats up with those wildcards?
To simplify filtering, a EventSpec String can contain a `*` or a `**` wildcard.  A `*` wildcard matches just one field between `::` delimiters.  A `**` wildcard matches one or more.

`'Service::*'` matches `'Service::Start'`, but not `'Service::Start::Now'`

`'Service::**'` matches both `'Service::Start'` and `'Service::Start::Now'`

## How do you use it?
It's easy.  Here's a self-explanatory example of a few Services that interact with each other.

```ruby
require_relative 'nanoservice'

# First, instantiate the Dispatcher and begin our monitoring thread.
#
dispatcher = Nanoservice::Dispatcher.new

# Now let's register a simple service.  The default EventSpec receives all messages.
#
dispatcher.register lambda { |event, payload|
  puts "Lambda sez I receive *ALL* events, like this one: #{event}"
}

# Usually, you'll want to supply an EventSpec.  You can also register a Block.
#
dispatcher.register(event_spec: 'OtherService::Message::*') do |event, payload|
  puts "I received only events from OtherService"
end

# Or, you can register a Method.  If the return value of any Service hook is a 
#   String or a Hash with an :event key, it will be sent back to the Dispatcher 
#   as a new message.
#
def bob(event, payload)
  puts "Bob is running because he got the event #{event}"
  { event: "Bob::Reply", payload: "Hi, I love a good message." }
end
dispatcher.register(service: method(:bob), event_spec: '*::GoodMessage::**')

# Here's a more complex (and probably typical) example.  We'll nnstantiate a new
#   object, allow it to process 5 messages simultaneously. This Class will need 
#   to be written to appropriately handle multiple Threads.
#
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
