module Protocol
  # The base class for protocol errors.
  class ProtocolError < StandardError; end

  # This exception is raise if an error was encountered while defining a
  # protocol specification.
  class SpecificationError < ProtocolError; end

  # Marker module for all exceptions related to check errors.
  module CheckError; end

  # If a protocol check failes this exception is raised.
  class BaseCheckError < ProtocolError
    include CheckError

    def initialize(protocol_message, message)
      super(message)
      @protocol_message = protocol_message
    end

    # Returns the Protocol::Message object, that caused this CheckError to be
    # raised.
    attr_reader :protocol_message

    def to_s
      "#{protocol_message}: #{super}"
    end

    def inspect
      "#<#{self.class.name}: #{to_s}>"
    end
  end

  # This exception is raised if a method was not implented in a class, that was
  # required to conform to the checked protocol.
  class NotImplementedErrorCheckError < BaseCheckError; end

  # This exception is raised if a method implented in a class didn't have the
  # required arity, that was required to conform to the checked protocol.
  class ArgumentErrorCheckError < BaseCheckError; end

  # This exception is raised if a method implented in a class didn't have the
  # expected block argument, that was required to conform to the checked
  # protocol.
  class BlockCheckError < BaseCheckError; end

  # This exception is raised if a precondition check failed (the yielded
  # block returned a non-true value) in a protocol description.
  class PreconditionCheckError < BaseCheckError; end

  # This exception is raised if a postcondition check failed (the yielded block
  # returned a non-true value) in a protocol description.
  class PostconditionCheckError < BaseCheckError; end

  # This exception collects CheckError exceptions and mixes in Enumerable for
  # further processing of them.
  class CheckFailed < ProtocolError
    include CheckError

    def initialize(*errors)
      @errors = errors
    end

    attr_reader :errors

    # Return true, if this CheckFailed doesn't contain any errors (yet).
    # Otherwise false is returned.
    def empty?
      errors.empty?
    end

    # Add +check_error+ to this CheckFailed instance.
    def <<(check_error)
      @errors << check_error
      self
    end

    # Iterate over all errors of this CheckFailed instance and pass each one to
    # +block+.
    def each_error(&block)
      errors.each(&block)
    end

    alias each each_error
    include Enumerable

    def to_s
      errors * "|"
    end

    def inspect
      "#<#{self.class.name}: #{errors.map { |e| e.inspect} * '|'}"
    end
  end
end
