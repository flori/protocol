module Protocol
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
end
