# ShortBus
Lightweight multi-threaded pub-sub message dispatcher for implementing self-contained service-oriented Ruby apps.

## What does it do?
The goal is to provide a lightweight message dispatcher/service API, with multi-threaded message publishing and subscription for closures (Lambdas/Blocks) and Methods.

ShortBus has no dependencies outside of the Ruby Core & Standard Libraries, and has less than 300 lines of code.

## What are the components?
A service is a participant in the SOA (Service Oriented Architecture) for publishing and/or subscribing to messages. To receive messages, the service subscribes to the Driver (Driver#subscribe); and is run as a callback in a dedicated thread or thread pool.

A message (as simple as a String, but ultimately converted to a ShortBus::Message object) is what is received, routed and sent to the recipient services by the Driver. A message can have an optional payload object, and subscribers can return values directly back to the publisher by using the Message object as a Queue (see "Message return values" below).

The Driver (ShortBus::Driver) is the brains of the operation. Once instantiated, a dedicated thread monitors the incoming queue, converts and routes the messages to the appropriate subscribers based on the message\_spec(s) supplied at the time of subscription.

## What does a message and a message\_spec look like?
In it's simplest form, a message can be a simple String like `'shutdown'`, but typically a more flexible, component based format is used, delimited by `/`, like `'OwnerService/Action/Argument'`.  The Driver will convert the message String into a ShortBus::Message object before routing.

A message\_spec can be supplied when subscribing in order to select which messages are received (ie: run the callback). A message\_spec can be a String (`'shutdown'`), a wildcard String (`'OwnerService/**'`), a Regexp, or even an Array or Set of multiple Strings and/or Regexps.

#### Wildcard String?
To simplify filtering, a message\_spec String can contain a `*` or a `**` wildcard. A `*` wildcard matches just one field between `/` delimiters. A `**` wildcard matches one or more.

`'Service/*'` matches `'Service/Start'`, but not `'Service/Start/Now'`

`'Service/**'` matches both `'Service/Start'` and `'Service/Start/Now'`

Wilcard Strings are turned into Regexps by the Driver.

## Message return values (Message as a Queue)
Typically speaking, services participating in a SOA do not get immediate return values, as an SOA is asynchronous. Since ShortBus generally runs as a monolithic application, we can cheat a bit for convenience, and pass return values back through the Message object (which is an inherited Queue class).

When a new Message is published via the Driver#publish method, the return value is the same Message object that subscribers receive.

The publisher can then #pop from that Message, which will block and wait for one of the subscribers to #push a "return value" into the Message on the other side. To make things more flexible, #pop (and #shift, #deq) has been extended to accept a numeric value, which acts as a timeout in seconds.

```ruby
return_val = driver.publish('Testing/Message')
  .pop(3)
```

If you don't want to use the Message return value functionality, you can ignore it, and Ruby's garbage collection will destroy the Message automatically when all subscriber callbacks have completed.

## How do you use it?

```ruby
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
driver.subscribe(message_spec: 'Chocolate/**') do |message|
  puts "2. Did I hear you say Chocolate?  (#{message}). I know what I'm making."
  'Chocolate/And/Strawberries'
end

# Subscribes a block with a message_spec filtering only some messages
#
driver.subscribe(message_spec: '**/Strawberries') do |message|
  puts "3. I only care about Strawberries: #{message}"
  'Strawberries'
end

# First lets just test it with an unrelated message
#
driver.publish 'Cookies/And/Cream'
sleep 0.1
puts

# Now lets try some interaction going between services
#
driver.publish 'Chocolate/Anything'
sleep 0.1
```
And here's what it looks like when we run it:

```
1. I like all foods, including Cookies/And/Cream

1. I like all foods, including Chocolate/Anything
2. Did I hear you say Chocolate?  (Chocolate/Anything). I know what I'm making.
1. I like all foods, including Chocolate/And/Strawberries
3. I only care about Strawberries: Chocolate/And/Strawberries
1. I like all foods, including Strawberries
```

## TODO
- HIGH: make mixin for easier integration (provide #driver #publish #register #unregister; callback method -> #subscribe)
- HIGH: create class for automated benchmarking & testing
- HIGH: make examples easier to read, smaller, more repeatable
- MEDIUM: convert all Queue's to SizedQueue's, with reasonable/adjustable limits
- MEDIUM: cascade block to Service object to avoid block.to\_proc slowdown
- MEDIUM: document api , make gem, publish
- LOW: Redis connector with JSON and binary-serialized object passing
- LOW: class based services (object instantiation on callback -> ?)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'short_bus'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install short_bus

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/robzr/short_bus.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
