require 'pp'
require 'timeout'

# Queue, with a few mods
#  - message (message.to_s) (string)
#  - optional payload (object)
#  - publisher (string or nil = anonymous)
#
module ShortBus
  class Message < Queue
    attr_accessor :publisher
    attr_reader :payload

    def initialize(*args)
      @message, @payload, @publisher = nil
      @semaphore = Mutex.new
      if populate args
        super()
      else
        raise ArgumentError.new "#Message: Invalid args #{args.pretty_inspect}"
      end
    end

    def merge(*args)
      arg_hash = process_args args
      if arg_hash[:message] 
        Message.new(
          message: arg_hash[:message] || @message,
          payload: arg_hash.has_key?(:payload) ? arg_hash[:payload] : @payload,
        )
      end
    end

    def payload=(arg)
      @semaphore.synchronize { @payload = arg }
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
      @message
    end

    private

    def populate(args)
      arg_hash = process_args args
      if arg_hash.has_key?(:message)
        @payload = arg_hash[:payload] if arg_hash.has_key?(:payload)
        @publisher = arg_hash[:publisher] if arg_hash.has_key?(:publisher)
        @message = arg_hash[:message]
      end
    end

    def process_args(args)
      if args[0].is_a? Array
        process_args args[0]
      else
        {}.tap do |me|
          if args[0].is_a? String
            me[:payload] = args[1] if args.length == 2
            me[:payload] = args.slice(1..-1) if args.length > 2
            me[:message] = args[0]
          elsif args[0].is_a?(Hash) && args[0].has_key?(:message)
            me[:payload] = args[0][:payload] if args[0].has_key?(:payload)
            me[:publisher] = args[0][:publisher] if args[0].has_key?(:publisher)
            me[:message] = args[0][:message]
          end
        end
      end
    end
  end
end
