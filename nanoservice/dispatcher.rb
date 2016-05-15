require 'pp'
require 'set'

module Nanoservice
  class Dispatcher
    #include Observable
    DEFAULT_OPTIONS = { 
      debug: false,
      default_event_spec: '**'
    }

    attr_reader :services, :threads
    attr_accessor :debug, :default_event_spec

    def initialize(options: {})
     @options = DEFAULT_OPTIONS.merge options 
     @debug = @options[:debug]
     @default_event_spec = options[:default_event_spec]

     @services = {}
     @messages = Queue.new
     @threads = { dispatcher: dispatch_loop }
    end

    def <<(message)
      send message
    end

    def register(arg, &block)
      args = {
        event_spec: @default_event_spec,
        name: nil,
        service: nil,
        thread_count: 1,
      }.merge arg.class.name == 'Hash' ? arg : { service: arg }
      args[:service] = block.to_proc if block_given?
      debug_message("register(#{args[:service]})")
      service_ref = ServiceRef.new(
        debug: @debug,
        dispatcher: self,
        event_spec: args[:event_spec],
        name: args[:name],
        service: args[:service],
        thread_count: args[:thread_count]
      )
      @services[service_ref.name] = service_ref
    end

    def send(message, payload = nil)
      if message.class.name == 'Hash'
        @messages << message if message.has_key? :event
      else
        @messages << { event: message, payload: payload }
      end
    end
    
    private

    def debug_message(message)
      STDERR.puts "Dispatcher::#{message}" if @debug
    end

    def dispatch_loop
      Thread.new do
        loop do
          route_message @messages.shift
        end
      end
    end

    def route_message(message)
      debug_message "routing_message(#{message})"
      @services.values.each do |service| 
        service.check(message[:event], message[:payload])
      end
    end
  end
end

