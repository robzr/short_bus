require 'pp'
require 'set'

module Nanoservice
  class Dispatcher

    DEFAULT_OPTIONS = { 
      debug: false,
      default_event_spec: '**'
    }

    attr_reader :services, :threads
    attr_accessor :debug, :default_event_spec

    def initialize(options: {})
     @options = DEFAULT_OPTIONS.merge options 
     @debug = @options[:debug]
     @default_event_spec = @options[:default_event_spec]

     @messages = Queue.new
     @services = {}

     @threads = { dispatcher: dispatch_loop }
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

      service_ref = Service.new(
        debug: @debug,
        dispatcher: self,
        event_spec: args[:event_spec],
        name: args[:name],
        service: args[:service],
        thread_count: args[:thread_count]
      )

      @services[service_ref.name] = service_ref
    end

    def send(event, payload = nil)
      message = Message.new(event, payload)
      @messages << message if message
      message
    end

    def <<(arg)
      case arg.class.name
      when 'String'
        send(arg)
      when 'Array'
        if arg[0].class.name == 'String'
          send(arg[0], arg.slice[1..-1])
        else
          raise ArgumentError => "Invalid << arg #{arg.pretty_inspect}"
        end
      else
        raise ArgumentError => "Invalid << arg #{arg.pretty_inspect}"
      end
    end

    def unregister(name)
      if @services.has_key? name
        @services[name].stop
        @services.delete name
      end      
    end
    
    private

    def debug_message(message)
      STDERR.puts "Dispatcher::#{message}" if @debug
    end

    def dispatch_loop
      Thread.new do
        loop { route_message @messages.shift }
      end
    end

    def route_message(message)
      debug_message "route_message(#{message})"
      @services.values.each { |service| service.check message }
    end
  end
end

