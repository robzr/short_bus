require 'observer'
require 'pp'
require 'set'

module ShortBus
  class Service
    attr_reader :name, :run_count, :threads

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
    
    def check(message)
      @run_queue << message if match message.event
    end

    def start
      while @threads.length < @thread_count
        @threads[@threads.length + 1] = Thread.new do
          loop { run_service @run_queue.shift }
        end
      end
    end

    def stop
      @threads.each do |index, thread|
        thread.kill
        @threads.delete index
      end
    end

    def match(event)
      @event_spec.match event
    end

    private

    def run_service(message)
      @run_count += 1
      case @service.class.name
      when 'Method', 'Proc'
        if @service.arity == 0
          @dispatcher << @service.call
        else
          @dispatcher << @service.call(message)
        end
      else
        raise ArgumentError => "Unknown service type: #{@service.class.name}"
      end
    end
  end
end
