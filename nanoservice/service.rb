require 'observer'
require 'pp'
require 'set'

module Nanoservice
  class Service
    attr_reader :name, :threads

    def initialize(
      debug: false,
      dispatcher: nil,
      event_spec: nil,
      name: nil,
      service: nil, 
      thread_count: 1
    )
      @debug = debug
      @dispatcher = dispatcher
      @event_spec = EventSpec.new event_spec
      @service = service
      @thread_count = thread_count
      @name = name || @service.to_s
      @run_queue = Queue.new
      @run_count = 0
      @threads = {}
      start
    end
    
    def check(event, payload)
      @run_queue << { 
        event: event,
        payload: payload
      } if match event
    end

    def start
      while @threads.length < @thread_count
        @threads[@threads.length + 1] = Thread.new do
          loop { run_service @run_queue.shift }
        end
      end
    end

    def stop!
      @threads.each do |index, thread|
        thread.kill
        @threads.delete index
      end
    end

    def match(event)
      @event_spec.match event
    end

    private

    def debug_message(message)
      STDERR.puts "Service::#{message}" if @debug
    end

    def maybe_send(message = nil)
      debug_message "maybe_send(#{message})"
      case message.class.name
      when 'String'
        @dispatcher << message
      when 'Hash'
        @dispatcher.send message if message.has_key? :event
      end
    end

    def run_service(message)
      @run_count += 1
      case @service.class.name
      when 'Method', 'Proc'
        maybe_send @service.call(message[:event], message[:payload])
      else
        raise ArgumentError => "Unknown service type: #{@service.class.name}"
      end
    end
  end
end
