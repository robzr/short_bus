require 'observer'
require 'pp'
require 'set'
require 'openssl'

module ShortBus
  class Service
    include DebugMessage
    CLASS_NAME = "Service"

    attr_reader :name, :run_count, :threads

    def initialize(
      debug: false,
      driver: nil,
      event_spec: nil,
      name: nil,
      recursive: false,
      service: nil, 
      thread_count: 1
    )
      @debug = debug
      @driver = driver
      @event_spec = EventSpec.new event_spec
      @recursive = recursive
      @service = service
      @thread_count = thread_count

      @name = name || @service.to_s || OpenSSL::HMAC.new(rand.to_s, 'sha1').to_s
      @run_queue = Queue.new
      @run_count = 0
      @threads = []
      start
    end
    
    def check(message)
      debug_message "[#{@name}]#check(#{message}) -> #{match(message.event)? "yes" : "no"}"
      if match message.event #&& ((message.sender != @name) || @recursive) 
          @run_queue << message if message.sender != @name || @recursive
      end
    end

    # TODO: graceful signal based reaping
    def start
      Thread.new do 
        loop do 
          @threads.delete_if { |thread| !thread.alive? }
          while @threads.length < @thread_count
            @threads << Thread.new do
              loop { run_service @run_queue.shift }
            end
          end
          sleep 0.1
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
      debug_message "[#{@name}]#run_service(#{message}) -> #{@service.class.name} ##{@service.arity}"
      case @service.class.name
      when 'Method', 'Proc'
        if @service.arity == 0
          @driver.send(message: @service.call, sender: @name)
        elsif [1, -1, -2].include? @service.arity
          @driver.send(message: @service.call(message), sender: @name)
        else
          raise ArgumentError => "Service invalid arg count: #{@service.class.name}"
        end
      else
        raise ArgumentError => "Unknown service type: #{@service.class.name}"
      end
    end
  end
end
