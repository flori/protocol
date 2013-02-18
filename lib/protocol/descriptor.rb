module Protocol
  # This class encapsulates the protocol description, to check the classes
  # against, if the Class#conform_to method is called with the protocol constant
  # as an argument.
  class Descriptor
    # Creates a new Protocol::Descriptor object.
    def initialize(protocol)
      @protocol = protocol
      @messages = {}
    end

    # Addes a new Protocol::Message instance to this Protocol::Descriptor
    # object.
    def add_message(message)
      @messages.key?(message.name) and raise SpecificationError,
        "A message named #{message.name} was already defined in #@protocol"
      @messages[message.name] = message
    end

    # Return all the messages stored in this Descriptor instance.
    def messages
      @messages.values
    end

    # Returns a string representation of this Protocol::Descriptor object.
    def inspect
      "#<#{self.class}(#@protocol)>"
    end

    def to_s
      messages * ', '
    end
  end
end
