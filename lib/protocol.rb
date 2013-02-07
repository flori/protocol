require 'protocol/version'

module Protocol
  require 'protocol/method_parser/ruby_parser'
  require 'protocol/utilities'

  class ::Object
    # Returns true if this object conforms to +protocol+, otherwise false.
    #
    # This is especially useful, if check_failure in the protocol is set to
    # :none or :warning, and conformance of a class to a protocol should be
    # checked later in runtime.
    def conform_to?(protocol)
      protocol.check(self, :none)
    end

    def conform_to!(protocol)
      extend(protocol)
    end

    # Define a protocol configured by +block+. Look at the methods of
    # ProtocolModule to get an idea on how to do that.
    def Protocol(&block)
      ProtocolModule.new(&block)
    end

    alias protocol Protocol
  end

  class ::Class
    # This method should be called at the end of a class definition, that is,
    # after all methods have been added to the class. The conformance to the
    # protocol of the class given as the argument is checked. See
    # Protocol::CHECK_MODES for the consequences of failure of this check.
    alias conform_to include

    # Returns true if this class conforms to +protocol+, otherwise false.
    #
    # This is especially useful, if check_failure in the protocol is set to
    # :none or :warning, and conformance of a class to a protocol should be
    # checked later in runtime.
    def conform_to?(protocol)
      protocol.check(self, :none)
    end
  end

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

  # The legal check modes, that influence the behaviour of the conform_to
  # method in a class definition:
  #
  # - :error -> raises a CheckFailed exception, containing other
  #   CheckError exceptions.
  # - :warning -> prints a warning to STDERR.
  # - :none -> does nothing.
  CHECK_MODES = [ :error, :warning, :none ]

  # This class is a proxy that stores postcondition blocks, which are called
  # after the result of the wrapped method was determined.
  class Postcondition
    instance_methods.each do |m|
      m.to_s =~ /\A(__|object_id|instance_eval\z|inspect\z)/ or undef_method m
    end

    def initialize(object)
      @object = object
      @blocks = []
    end

    # This is the alternative result "keyword".
    def __result__
      @result
    end

    # This is the result "keyword" which can be used to query the result of
    # wrapped method in a postcondition clause.
    def result
      if @object.respond_to? :result
        warn "#{@object.class} already defines a result method, "\
          "try __result__ instead"
        @object.__send__(:result)
      else
        @result
      end
    end

    # This is the "keyword" to be used instead of +self+ to refer to current
    # object.
    def myself
      @object
    end

    # :stopdoc:
    def __result__=(result)
      @result = result
    end

    def __check__
      @blocks.all? { |block| instance_eval(&block) }
    end

    def __add__(block)
      @blocks << block
      self
    end
    # :startdoc:

    # Send all remaining messages to the object.
    def method_missing(*a, &b)
      @object.__send__(*a, &b)
    end
  end

  # A Message consists of the name of the message (=method name), and the
  # method argument's arity.
  class Message
    include Comparable

    # Creates a Message instance named +name+, with the arity +arity+.
    # If +arity+ is nil, the arity isn't checked during conformity tests.
    def initialize(protocol, name, arity = nil, block_expected = false)
      name = name.to_s
      @protocol, @name, @arity, @block_expected =
        protocol, name, arity, !!block_expected
    end

    # The protocol this message was defined in.
    attr_reader :protocol

    # Name of this message.
    attr_reader :name

    # Arity of this message = the number of arguments.
    attr_accessor :arity

    # Set to true if this message should expect a block.
    def block_expected=(block_expected)
      @block_expected = !!block_expected
    end

    # Returns true if this message is expected to include a block argument.
    def block_expected?
      @block_expected
    end

    # Message order is alphabetic name order.
    def <=>(other)
      name <=> other.name
    end

    # Returns true if this message equals the message +other+.
    def ==(other)
      name == other.name && arity == other.arity
    end

    # Returns the shortcut for this message of the form "methodname(arity)".
    def shortcut
      "#{name}(#{arity}#{block_expected? ? '&' : ''})"
    end

    # Return a string representation of this message, in the form
    # Protocol#name(arity).
    def to_s
      "#{protocol.name}##{shortcut}"
    end

    # Concatenates a method signature as ruby code to the +result+ string and
    # returns it.
    def to_ruby(result = '')
      if arity
        result << "  def #{name}("
        args = if arity >= 0
          (1..arity).map { |i| "x#{i}" }
        else
          (1..~arity).map { |i| "x#{i}" } << '*rest'
        end
        if block_expected?
          args << '&block'
        end
        result << args * ', '
        result << ") end\n"
      else
        result << "  understand :#{name}\n"
      end
    end

    # The class +klass+ is checked against this Message instance. A CheckError
    # exception will called, if either a required method isn't found in the
    # +klass+, or it doesn't have the required arity (if a fixed arity was
    # demanded).
    def check(object, checked)
      check_message = object.is_a?(Class) ? :check_class : :check_object
      if checked.key?(name)
        true
      else
        checked[name] = __send__(check_message, object)
      end
    end

    private

    # Check class +klass+ against this Message instance, and raise a CheckError
    # exception if necessary.
    def check_class(klass)
      unless klass.method_defined?(name)
        raise NotImplementedErrorCheckError.new(self,
            "method '#{name}' not implemented in #{klass}")
      end
      check_method = klass.instance_method(name)
      if arity and (check_arity = check_method.arity) != arity
        raise ArgumentErrorCheckError.new(self,
              "wrong number of arguments for protocol"\
              " in method '#{name}' (#{check_arity} for #{arity}) of #{klass}")
      end
      if block_expected?
        modul = Utilities.find_method_module(name, klass.ancestors)
        parser = MethodParser.new(modul, name)
        parser.block_arg? or raise BlockCheckError.new(self,
          "expected a block argument for #{klass}")
      end
      arity and wrap_method(klass)
      true
    end

    # :stopdoc:
    MyArray = Array.dup # Hack to make checking against Array possible.
    # :startdoc:

    def wrap_method(klass)
      check_name = "__protocol_check_#{name}"
      if klass.method_defined?(check_name)
        inner_name = "__protocol_inner_#{name}"
        unless klass.method_defined?(inner_name)
          args =
            if arity >= 0
              (1..arity).map { |i| "x#{i}," }
            else
              (1..~arity).map { |i| "x#{i}," } << '*rest,'
            end.join
          wrapped_call = %{
            alias_method :'#{inner_name}', :'#{name}'

            def precondition
              yield or
                raise Protocol::PreconditionCheckError.new(
                  ObjectSpace._id2ref(#{__id__}),
                  "precondition failed for \#{self.class}")
            end unless method_defined?(:precondition)

            def postcondition(&block)
              post_name = "__protocol_#{klass.__id__.abs}_postcondition__"
              (Thread.current[post_name][-1] ||= Protocol::Postcondition.new(
                self)).__add__ block
            end unless method_defined?(:postcondition)

            def #{name}(#{args} &block)
              result = nil
              post_name = "__protocol_#{klass.__id__.abs}_postcondition__"
              (Thread.current[post_name] ||= MyArray.new) << nil
              __send__('#{check_name}', #{args} &block)
              if postcondition = Thread.current[post_name].last
                begin
                  reraised = false
                  result = __send__('#{inner_name}', #{args} &block)
                  postcondition.__result__= result
                rescue Protocol::PostconditionCheckError => e
                  reraised = true
                  raise e
                ensure
                  unless reraised
                    postcondition.__check__ or
                      raise Protocol::PostconditionCheckError.new(
                        ObjectSpace._id2ref(#{__id__}),
                        "postcondition failed for \#{self.class}, result = " +
                        result.inspect)
                  end
                end
              else
                result = __send__('#{inner_name}', #{args} &block)
              end
              result
            rescue Protocol::CheckError => e
              case ObjectSpace._id2ref(#{__id__}).protocol.mode
              when :error
                raise e
              when :warning
                warn e
              end
            ensure
              Thread.current[post_name].pop
              Thread.current[post_name].empty? and
                Thread.current[post_name] = nil
            end
          }
          klass.class_eval wrapped_call
        end
      end
    end

    # Check object +object+ against this Message instance, and raise a
    # CheckError exception if necessary.
    def check_object(object)
      if !object.respond_to?(name)
        raise NotImplementedErrorCheckError.new(self,
            "method '#{name}' not responding in #{object}")
      end
      check_method = object.method(name)
      if arity and (check_arity = check_method.arity) != arity
        raise ArgumentErrorCheckError.new(self,
            "wrong number of arguments for protocol"\
            " in method '#{name}' (#{check_arity} for #{arity}) of #{object}")
      end
      if block_expected?
        if object.singleton_methods(false).map { |m| m.to_s } .include?(name)
          parser = MethodParser.new(object, name, true)
        else
          ancestors = object.class.ancestors
          modul = Utilities.find_method_module(name, ancestors)
          parser = MethodParser.new(modul, name)
        end
        parser.block_arg? or raise BlockCheckError.new(self,
          "expected a block argument for #{object}:#{object.class}")
      end
      if arity and not protocol === object
        object.extend protocol
        wrap_method(class << object ; self ; end)
      end
      true
    end
  end

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

  # A ProtocolModule object
  class ProtocolModule < Module
    # Creates an new ProtocolModule instance.
    def initialize(&block)
      @descriptor = Descriptor.new(self)
      @mode = :error
      module_eval(&block)
    end

    # The current check mode :none, :warning, or :error (the default).
    attr_reader :mode

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
      first = true
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

    # Check the conformity of +object+ recursively. This method returns either
    # false OR true, if +mode+ is :none or :warning, or raises an
    # CheckFailed, if +mode+ was :error.
    def check(object, mode = @mode)
      checked = {}
      result = true
      errors = CheckFailed.new
      each do |message|
        begin
          message.check(object, checked)
        rescue CheckError => e
          case mode
          when :error
            errors << e
          when :warning
            warn e.to_s
            result = false
          when :none
            result = false
          end
        end
      end
      raise errors unless errors.empty?
      result
    end

    alias =~ check

    # Return all messages for whick a check failed.
    def check_failures(object)
      check object
    rescue CheckFailed => e
      return e.errors.map { |e| e.protocol_message }
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
      super
      if modul.is_a? Class and @mode == :error or @mode == :warning
        $DEBUG and warn "#{name} is checking class #{modul}"
        check modul
      end
    end

    def extend_object(object)
      super
      if @mode == :error or @mode == :warning
        $DEBUG and warn "#{name} is checking class #{object}"
        check object
      end
    end

    # Sets the check mode to +id+. +id+ should be one of :none, :warning, or
    # :error. The mode to use while doing a conformity check is always the root
    # module, that is, the modes of the included modules aren't important for
    # the check.
    def check_failure(mode)
      CHECK_MODES.include?(mode) or
        raise ArgumentError, "illegal check mode #{mode}"
      @mode = mode
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

    # Inherit a method signature from an instance method named +methodname+ of
    # +modul+. This means that this protocol should understand these instance
    # methods with their arity and block expectation. Note that automatic
    # detection of blocks does not work for Ruby methods defined in C. You can
    # set the +block_expected+ argument if you want to do this manually.
    def inherit(modul, methodname, block_expected = nil)
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
      !!@implementation
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
