require 'observer'
require 'pp'
require 'set'

module NanoSOA
  class Dispatcher
    #include Observable
    THREAD_THROTTLE = 0.005

    attr_reader :services, :threads
    attr_accessor :default_event_spec

    def initialize(
      options: {}
    )
     @default_event_spec = options[:default_event_spec] || '**'
     @services = {}
     @messages = Queue.new
     @threads = { dispatcher: dispatch_loop }
    end

    def <<(message)
      self.send message
    end

    def register(
      event_spec: @default_event_spec,
      name: nil,
      service: nil,
      thread_count: 1,
      &block
    )
      if block_given?
        service_ref = ServiceRef.new(
          event_spec: event_spec,
          name: name,
          thread_count: thread_count,
          &block 
        )
      else
        service_ref = ServiceRef.new(
          event_spec: event_spec,
          name: name,
          service: service,
          thread_count: thread_count
        )
      end
      @services[service_ref.name] = service_ref
    end

    def send(message, payload = nil)
      if message.class.name == 'Hash'
        @messages << message
      else
        @messages << { message: message, payload: payload }
      end
    end
    
    private

    def dispatch_loop
      Thread.new do
        loop do
          route_message @messages.shift
        end
      end
    end

    def route_message(message)
      @services.values.each do |service| 
        service.check(message[:message], message[:payload])
      end
    end
  end
end

