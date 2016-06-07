require 'pp'
require 'timeout'

# Queue, with a few mods
#  - name (message.to_s) (string)
#  - optional payload (object)
#  - publisher (string or nil = anonymous)
#
module ShortBus
  class Message < Queue
    attr_reader :payload
    attr_accessor :publisher

    def initialize(*args)
      @name, @payload, @publisher = nil
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
      @name
    end

    private

    def process_args(args)
      if args.is_a?(Array) && args.length > 0
        if args[0].is_a? Array
          process_args args[0]
        elsif args[0].is_a? String
          @payload = args[1] if args.length == 2
          @payload = args.slice(1..-1) if args.length > 2
          @name = args[0]
        elsif args[0].is_a?(Hash) && args[0].has_key?(:message)
          @payload = args[0][:payload] if args[0].has_key?(:payload)
          @publisher = args[0][:publisher] if args[0].has_key?(:publisher)
          @name = args[0][:message]
        end
      end
    end
  end
end
