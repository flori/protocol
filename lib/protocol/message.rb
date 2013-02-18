module Protocol
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
end
