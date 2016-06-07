require 'pp'
require 'set'

module ShortBus
  class Driver
    include DebugMessage

    attr_reader :services, :threads
    attr_accessor :debug

    def initialize(*options)
      @options = { 
        debug: false,
        default_event_spec: '**',
        default_sender_spec: nil,
        default_thread_count: 1
      }
      @options.merge! options[0] if options[0]
      @debug = @options[:debug]

      @messages = Queue.new
      @services = {}
      @threads = { route_message_loop: launch_route_message_loop }
    end

    def register(*args, &block)
      service_args = {
        debug: @debug,
        event_spec: @options[:default_event_spec],
        name: nil,
        sender_spec: @options[:default_sender_spec],
        service: nil,
        thread_count: @options[:default_thread_count],
      }.merge args[0].is_a?(Hash) ? args[0] : { service: args[0] }

      service_args[:service] = block.to_proc if block_given?

      debug_message("#register service: #{service_args[:service]}")

      service_ref = Service.new(
        debug: service_args[:debug],
        driver: self,
        event_spec: service_args[:event_spec],
        name: service_args[:name],
        sender_spec: service_args[:sender_spec],
        service: service_args[:service],
        thread_count: service_args[:thread_count]
      )
      @services[service_ref.name] = service_ref
    end

    def send(arg)
      if message = convert_to_message(arg)
        @messages.push message
        message
      end
    end

    alias_method :<<, :send

    def unregister(service)
      if service.is_a? ShortBus::Service
        unregister(service.name)
      elsif @services.has_key? service
        @services[service].stop
        @services.delete service
      end      
    end
    
    private

    def convert_to_message(arg)
      if arg.is_a? ShortBus::Message
        arg
      elsif arg.is_a? String
        Message.new(arg)
      elsif arg.is_a?(Array) && arg[0].is_a?(String)
        Message.new(arg)
      elsif arg.is_a?(Hash) && arg.has_key?(:event)
        sender = arg.has_key?(:sender) ? arg[:sender] : nil
        payload = arg.has_key?(:payload) ? arg[:payload] : nil
        Message.new(event: arg[:event], payload: payload, sender: sender)
      end
    end

    def launch_route_message_loop
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

