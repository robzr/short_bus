require 'pp'

# We're just a Queue, but with a couple extras:
#  - event (string)
#  - optional payload (object)
#  - optional sender
#
module ShortBus
  class Message < Queue
    attr_reader :event, :payload
    attr_accessor :sender

    def initialize(*args)
      @event, @payload, @sender = nil
      if process_args args
        super()
      else
        raise ArgumentError => "#Message: Invalid args #{args.pretty_inspect}"
      end
    end

    def to_s
      @event
    end

    private

    def process_args(args)
      if args.class.name == 'Array' && args.length > 0
        case args[0].class.name
        when 'Array'
          process_args args[0]
        when 'String'
          @payload = args[1] if args.length == 2
          @payload = args.slice(1..-1) if args.length > 2
          @event = args[0]
        when 'Hash' && args[0].has_key?(:event)
          @payload = args[0][:payload] if args[0].has_key?(:payload)
          @sender = args[0][:sender] if args[0].has_key?(:sender)
          @event = args[0][:event]
        end
      end
    end
  end
end
