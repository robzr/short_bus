require 'pp'

module ShortBus
  ##
  # For printing out all messages
  class Monitor

    DEFAULT_MONITOR_OPTIONS = {
      message_spec: nil,
      name: 'ShortBus::Monitor',
      suppress_payload: false,
      suppress_publisher: false,
      publisher_spec: nil,
      thread_count: 1
    }.freeze

    def initialize(*args)
      @options = DEFAULT_MONITOR_OPTIONS.merge(service: method(:monitor))
      @suppress_payload, @suppress_publisher = nil

      if args[0].is_a?(Hash) && args[0].key?(:driver)
        @options.merge! args[0]
        @driver = @options[:driver]
        @options.delete(:driver)
      elsif args.is_a?(Array) && args.length == 1
        @driver = args[0]
      else
        raise ArgumentError, 'No driver passed.'
      end

      @suppress_payload = @options.delete(:suppress_payload)
      @suppress_publisher = @options.delete(:suppress_publisher)

      start
    end

    def monitor(message)
      puts "[#{@options[:name]}]  message = #{message}"
      printf(
        "  %s  payload = %s\n",
        @options[:name] ? ' ' * @options[:name].length : '',
        message.payload.inspect
      ) if message.payload && !@suppress_payload
      printf(
        "  %spublisher = %s\n",
        @options[:name] ? ' ' * @options[:name].length : '',
        message.publisher ? message.publisher : '*ANONYMOUS*'
      ) unless @suppress_publisher
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
