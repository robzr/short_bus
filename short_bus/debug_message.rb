module DebugMessage
  def debug_message(message)
    STDERR.puts "#{caller.first.sub(/^.*\//, '').sub(/:.*$/, '')}::#{message}" if @debug
  end
end
