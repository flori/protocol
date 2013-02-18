require 'protocol/version'

module Protocol
  require 'protocol/method_parser/ruby_parser'
  require 'protocol/utilities'
  require 'protocol/protocol_module'
  require 'protocol/post_condition'
  require 'protocol/descriptor'
  require 'protocol/message'
  require 'protocol/errors'
  require 'protocol/xt'

  # The legal check modes, that influence the behaviour of the conform_to
  # method in a class definition:
  #
  # - :error -> raises a CheckFailed exception, containing other
  #   CheckError exceptions.
  # - :warning -> prints a warning to STDERR.
  # - :none -> does nothing.
  CHECK_MODES = [ :error, :warning, :none ]
end
