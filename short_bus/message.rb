require 'pp'
require 'timeout'

# Queue, with a few mods
#  - event (string)
#  - optional payload (object)
#  - sender (string or nil = anonymous)
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
        raise ArgumentError.new "#Message: Invalid args #{args.pretty_inspect}"
      end
    end

    def pop(time_out=nil)
      if time_out.is_a? Numeric
        begin
          Timeout.timeout(time_out) { super() }
        rescue Timeout::Error
        end
      else
        super(time_out)
      end
    end

    alias_method :shift, :pop
    alias_method :deq, :pop

    def to_s
      @event
    end

    private

    def process_args(args)
      if args.is_a?(Array) && args.length > 0
        if args[0].is_a? Array
          process_args args[0]
        elsif args[0].is_a? String
          @payload = args[1] if args.length == 2
          @payload = args.slice(1..-1) if args.length > 2
          @event = args[0]
        elsif args[0].is_a?(Hash) && args[0].has_key?(:event)
          @payload = args[0][:payload] if args[0].has_key?(:payload)
          @sender = args[0][:sender] if args[0].has_key?(:sender)
          @event = args[0][:event]
        end
      end
    end
  end
end
