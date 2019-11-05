module Protocol
  # A ProtocolModule object
  class ProtocolModule < Module
    # Creates an new ProtocolModule instance.
    def initialize(&block)
      @descriptor     = Descriptor.new(self)
      @implementation = false
      block and module_eval(&block)
    end

    # Returns all the protocol descriptions to check against as an Array.
    def descriptors
      descriptors = []
      protocols.each do |a|
        descriptors << a.instance_variable_get(:@descriptor)
      end
      descriptors
    end

    # Return self and all protocols included into self.
    def protocols
      ancestors.select { |modul| modul.is_a? ProtocolModule }
    end

    # Concatenates the protocol as Ruby code to the +result+ string and return
    # it. At the moment this method only supports method signatures with
    # generic argument names.
    def to_ruby(result = '')
      result << "#{name} = Protocol do"
      if messages.empty?
        result << "\n"
      else
        messages.each do |m|
          result << "\n"
          m.to_ruby(result)
        end
      end
      result << "end\n"
    end

    # Returns all messages this protocol (plus the included protocols) consists
    # of in alphabetic order. This method caches the computed result array. You
    # have to call #reset_messages, if you want to recompute the array in the
    # next call to #messages.
    def messages
      result = []
      seen = {}
      descriptors.each do |d|
        dm = d.messages
        dm.delete_if do |m|
          delete = seen[m.name]
          seen[m.name] = true
          delete
        end
        result.concat dm
      end
      result.sort!
    end

    alias to_a messages

    # Reset the cached message array. Call this if you want to change the
    # protocol dynamically after it was already used (= the #messages method
    # was called).
    def reset_messages
      @messages = nil
      self
    end

    # Returns true if it is required to understand the
    def understand?(name, arity = nil)
      name = name.to_s
      !!find { |m| m.name == name && (!arity || m.arity == arity) }
    end

    # Return the Message object named +name+ or nil, if it doesn't exist.
    def [](name)
      name = name.to_s
      find { |m| m.name == name }
    end

    # Return all message whose names matches pattern.
    def grep(pattern)
      select { |m| pattern === m.name }
    end

    # Iterate over all messages and yield to all of them.
    def each_message(&block) # :yields: message
      messages.each(&block)
      self
    end
    alias each each_message

    include Enumerable

    # Returns a string representation of this protocol, that consists of the
    # understood messages. This protocol
    #
    #  FooProtocol = Protocol do
    #    def bar(x, y, &b) end
    #    def baz(x, y, z) end
    #    def foo(*rest) end
    #  end
    #
    # returns this string:
    #
    #  FooProtocol#bar(2&), FooProtocol#baz(3), FooProtocol#foo(-1)
    def to_s
      messages * ', '
    end

    # Returns a short string representation of this protocol, that consists of
    # the understood messages. This protocol
    #
    #  FooProtocol = Protocol do
    #    def bar(x, y, &b) end
    #    def baz(x, y, z) end
    #    def foo(*rest) end
    #  end
    #
    # returns this string:
    #
    #  #<FooProtocol: bar(2&), baz(3), foo(-1)>
    def inspect
      "#<#{name}: #{messages.map { |m| m.shortcut } * ', '}>"
    end

    # Check the conformity of +object+ recursively and raise an exception if it
    # doesn't.
    def check!(object)
      checked = {}
      errors = CheckFailed.new
      each do |message|
        begin
          message.check(object, checked)
        rescue CheckError => e
          errors << e
        end
      end
      errors.empty? or raise errors
      true
    end

    alias =~ check!

    # Check the conformity of +object+ recursively and return true iff it does.
    def check(object)
      check!(object)
    rescue CheckFailed
      false
    else
      true
    end

    # Return all messages for whick a check failed.
    def check_failures(object)
      check!(object)
    rescue CheckFailed => e
      e.errors.map { |e| e.protocol_message }
    end

    # This callback is called, when a module, that was extended with Protocol,
    # is included (via Modul#include/via Class#conform_to) into some other
    # module/class.
    # If +modul+ is a Class, all protocol descriptions of the inheritance tree
    # are collected and the given class is checked for conformance to the
    # protocol. +modul+ isn't a Class and only a Module, it is extended with
    # the Protocol
    # module.
    def included(modul)
      result = super
      if modul.is_a? Class
        check! modul
      end
      result
    end

    def extend_object(object)
      result = super
      check! object
      result
    end

    # This method defines one of the messages, the protocol in question
    # consists of: The messages which the class, that conforms to this
    # protocol, should understand and respond to. An example shows best
    # which +message+descriptions_ are allowed:
    #
    #  MyProtocol = Protocol do
    #    understand :bar            # conforming class must respond to :bar
    #    understand :baz, 3         # c. c. must respond to :baz with 3 args.
    #    understand :foo, -1        # c. c. must respond to :foo, any number of args.
    #    understand :quux, 0, true  # c. c. must respond to :quux, no args + block.
    #    understand :quux1, 1, true # c. c. must respond to :quux, 1 arg + block.
    #  end
    def understand(methodname, arity = nil, block_expected = false)
      m = Message.new(self, methodname.to_s, arity, block_expected)
      @descriptor.add_message(m)
      self
    end

    def parse_instance_method_signature(modul, methodname)
      methodname = methodname.to_s
      method = modul.instance_method(methodname)
      real_module = Utilities.find_method_module(methodname, modul.ancestors)
      parser = MethodParser.new(real_module, methodname)
      Message.new(self, methodname, method.arity, parser.block_arg?)
    end
    private :parse_instance_method_signature

    # Infer a method signature from an instance method named +methodname+ of
    # +modul+. This means that this protocol should understand these instance
    # methods with their arity and block expectation. Note that automatic
    # detection of blocks does not work for Ruby methods defined in C. You can
    # set the +block_expected+ argument if you want to do this manually.
    def infer(modul, methodname = modul.public_instance_methods(false), block_expected = nil)
      Module === modul or
        raise TypeError, "expected Module not #{modul.class} as modul argument"
      methodnames = methodname.respond_to?(:to_ary) ?
        methodname.to_ary :
        [ methodname ]
      methodnames.each do |methodname|
        m = parse_instance_method_signature(modul, methodname)
        block_expected and m.block_expected = block_expected
        @descriptor.add_message m
      end
      self
    end

    # Switch to implementation mode. Defined methods are added to the
    # ProtocolModule as instance methods.
    def implementation
      @implementation = true
    end

    # Return true, if the ProtocolModule is currently in implementation mode.
    # Otherwise return false.
    def implementation?
      @implementation
    end

    # Switch to specification mode. Defined methods are added to the protocol
    # description in order to be checked against in later conformance tests.
    def specification
      @implementation = false
    end

    # Return true, if the ProtocolModule is currently in specification mode.
    # Otherwise return false.
    def specification?
      !@implementation
    end

    # Capture all added methods and either leave the implementation in place or
    # add them to the protocol description.
    def method_added(methodname)
      methodname = methodname.to_s
      if specification? and methodname !~ /^__protocol_check_/
        protocol_check = instance_method(methodname)
        parser = MethodParser.new(self, methodname)
        if parser.complex?
          define_method("__protocol_check_#{methodname}", protocol_check)
          understand methodname, protocol_check.arity, parser.block_arg?
        else
          understand methodname, protocol_check.arity, parser.block_arg?
        end
        remove_method methodname
      else
        super
      end
    end
  end
end
