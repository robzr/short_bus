##
# module method for outputting debugging messages
module DebugMessage
  def debug_message(message)
    (@debug_message_output_filehandle || STDERR).printf(
      "%s::%s\n",
      caller.first.sub(%r{^.*/([^:]*).*}, '\1'),
      message
    ) if @debug
  end
end
