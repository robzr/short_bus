module DebugMessage
  def debug_message(message)
    (@debug_message_fh ||= STDERR).printf(
      "%s::%s\n",
      caller.first.sub(/^.*\/([^:]*).*/, '\1'),
      message
    ) if @debug
  end
end
