require 'pp'

module ShortBus
  class Monitor

    def initialize(*args)
      @options = {
        event_spec: nil,
        name: 'ShortBus::Monitor',
        suppress_payload: false,
        suppress_sender: false,
        sender_spec: nil,
        service: self.method(:monitor),
        thread_count: 1
      }
      @suppress_payload, @suppress_sender = nil
      if args[0].is_a?(Hash) && args[0].has_key?(:driver)
        @options.merge! args[0]
        @driver = @options[:driver]
        @options.delete(:driver)
      elsif args.is_a?(Array) && args.length == 1
        @driver = args[0]
      else
        raise ArgumentError, 'No driver passed.'
      end
      @suppress_payload = @options.delete(:suppress_payload)
      @suppress_sender = @options.delete(:suppress_sender)
      start
    end

    def monitor(message)
      printf("->%s event = #{message}\n",
             @options[:name] ? "[#{@options[:name]}]" : '')
      if message.payload && !@suppress_payload
        puts "  -> payload = #{message.payload.inspect}"
      end
      if !@suppress_sender
        puts "  ->  sender = #{message.sender ? message.sender : '*ANONYMOUS*'}"
      end
      nil
    end

    def start
      @service = @driver.subscribe(@options)
    end

    def stop
      @driver.unsubscribe @service
    end
  end
end
