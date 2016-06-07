module DebugMessage
  def debug_message(message)
    @debug_message_fh ||= STDERR
    @debug_message_fh.printf(
      "%s::%s\n",
      caller.first
        .sub(/^.*\//, '')
        .sub(/:.*$/, ''),
      message
    ) if @debug
  end
end
