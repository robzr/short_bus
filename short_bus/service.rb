require 'observer'
require 'pp'
require 'set'
require 'openssl'

module ShortBus
  class Service
    include DebugMessage

    attr_reader :name, :threads

    def initialize(
      debug: false,
      driver: nil,
      event_spec: nil,
      name: nil,
      recursive: false,
      sender_spec: nil,
      service: nil, 
      thread_count: 1
    )
      @debug = debug
      @driver = driver
      @event_spec = event_spec ? Spec.new(event_spec) : nil
      @recursive = recursive
      @sender_spec = sender_spec ? Spec.new(sender_spec) : nil
      @service = service
      @thread_count = thread_count

      @name = name || @service.to_s || OpenSSL::HMAC.new(rand.to_s, 'sha1').to_s
      @run_queue = Queue.new
      @threads = []
      start
    end
    
    def check(message)
      debug_message "[#{@name}]#check(#{message})"
      if match_event(message.event) && match_sender(message.sender)
        @run_queue << message if message.sender != @name || @recursive
      end
    end

    # TODO: consider some mechanism to pass Exceptions up to the main thread,
    #   perhaps with a whitelist, optional logging, something clean.
    def service_thread
      Thread.new do 
        begin
          loop { run_service @run_queue.shift }
        rescue Exception => exc
          debug_message "[#{@name}]service_thread => #{exc.inspect}"
          abort if exc.is_a? SystemExit
          retry
        end 
      end 
    end

    def start
      #@threads.delete_if { |thread| !thread.alive? }
      @threads << service_thread while @threads.length < @thread_count
    end

    def stop
      @threads.each_index do |index|
        @threads[index].kill
        @threads[index].join
        @threads.delete index
      end
    end

    def to_s
      @name
    end

    private

    def match_event(event)
      @event_spec ? @event_spec.match(event) : true
    end

    def match_sender(sender)
      @sender_spec ? @sender_spec.match(sender) : true
    end

    def run_service(message)
      debug_message "[#{@name}]#run_service(#{message}) -> #{@service.class.name} ##{@service.arity}"
      if @service.is_a?(Proc) || @service.is_a?(Method)
        if @service.arity == 0
          @driver.send(message: @service.call, sender: @name)
        elsif [1, -1, -2].include? @service.arity
          @driver.send(message: @service.call(message), sender: @name)
        else
          raise ArgumentError, "Service invalid arg count: #{@service.class.name}"
        end
      else
        raise ArgumentError, "Unknown service type: #{@service.class.name}"
      end
    end
  end
end
