module DebugMessage
  def debug_message(message)
    if @debug
      STDERR.puts "#{caller.first.sub(/^.*\//, '').sub(/:.*$/, '')}::#{message}"
    end
  end
end
