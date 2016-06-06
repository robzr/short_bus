require 'pp'
require 'set'

module ShortBus
  class Driver
    include DebugMessage

    DEFAULT_OPTIONS = { 
      debug: false,
      default_event_spec: '**'
    }

    attr_reader :services, :threads
    attr_accessor :debug, :default_event_spec

    def initialize(*options)
     @options = DEFAULT_OPTIONS
     @options.merge! options[0] if options[0]
     @debug = @options[:debug]
     @default_event_spec = @options[:default_event_spec]

     @messages = Queue.new
     @services = {}

     @threads = { driver: driver_loop }
    end

    def register(*args, &block)
      arg = args[0]
      args = {
        debug: @debug,
        event_spec: @default_event_spec,
        name: nil,
        service: nil,
        thread_count: 1,
      }.merge arg.class.name == 'Hash' ? arg : { service: arg }

      args[:service] = block.to_proc if block_given?

      debug_message("register(#{args[:service]})")

      service_ref = Service.new(
        debug: args[:debug],
        driver: self,
        event_spec: args[:event_spec],
        name: args[:name],
        service: args[:service],
        thread_count: args[:thread_count]
      )
      @services[service_ref.name] = service_ref
    end

    def <<(arg)
      if message = convert_to_message(arg)
        @messages.push message
        message
      end
    end

    def send(event: nil, message: nil, payload: nil, sender: nil)
      if message
        message = convert_to_message message
        message.sender = sender if sender
      else
        message = Message.new(event: event, payload: payload, sender: sender)
      end
      self << message
    end

    def unregister(name)
      if @services.has_key? name
        @services[name].stop
        @services.delete name
      end      
    end
    
    private

    def convert_to_message(arg)
      if arg.class.name == 'ShortBus::Message'
        arg
      elsif arg.class.name == 'String'
        Message.new(arg)
      elsif arg.class.name == 'Array' && arg[0].class.name == 'String'
        Message.new(arg)
      elsif arg.class.name == 'Hash' && arg.has_key?(:event)
        sender = arg.has_key?(:sender) ? arg[:sender] : nil
        payload = arg.has_key?(:payload) ? arg[:payload] : nil
        Message.new(event: arg[:event], payload: payload, sender: sender)
      end
    end

    def driver_loop
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

