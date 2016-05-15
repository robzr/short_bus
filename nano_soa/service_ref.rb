require 'observer'
require 'pp'
require 'set'

module NanoSOA
  class ServiceRef
    attr_reader :name, :threads

    def initialize(
      debug: false,
      dispatcher: nil,
      event_spec: nil,
      name: nil,
      service: nil, 
      thread_count: 1,
      &block
    )
      @debug = debug
      @dispatcher = dispatcher
      @event_spec = EventSpec.new event_spec
      @service = block_given? ? block.to_proc : service
      @thread_count = thread_count
      @name = name || @service.to_s
      @run_queue = Queue.new
      @run_count = 0
      @threads = {}
      launch_threads
    end
    
    def check(event, payload)
      @run_queue << { 
        event: event,
        payload: payload
      } if match event
    end

    def match(event)
      @event_spec.match event
    end

    private

    def debug_message(message)
      STDERR.puts "ServiceRef::#{message}" if @debug
    end

    def launch_threads
      while @threads.length < @thread_count
        @threads[@threads.length + 1] = Thread.new {
          loop do
            message = @run_queue.shift
            run_service(message[:event], message[:payload])
          end
        }
      end
    end

    def maybe_send(message = nil)
      case message.class.name
      when 'String'
        debug_message "maybe_send(String: message)"
        @dispatcher << message
      when 'Hash'
        if message.has_key? :event
          debug_message "maybe_send(Hash: message) sending #{message}"
          @dispatcher.send message
        else
          debug_message "maybe_send(Hash: message) not-sending #{message}"
        end
      else
        debug_message "maybe_send not sending (class: #{message.class.name})"
      end
    end

    def run_service(event, payload)
      @run_count += 1
      case @service.class.name
      when 'Method', 'Proc'
        maybe_send @service.call(event, payload)
      else
        raise ArgumentError => "Unknown service type: #{@service.class.name}"
      end
    end
  end
end
