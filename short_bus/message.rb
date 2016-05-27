require 'pp'

# We're just a Queue, but with an event (string) and a payload (object) included
#
module ShortBus
  class Message < Queue
    attr_reader :event, :payload

    def initialize(event, arg = nil)
      if event.class.name == 'String'
        @event = event
        @payload = arg
        super()
      else
        raise ArgumentError => "Event must be a String"
      end
    end

    def to_s
      @event
    end
  end
end
