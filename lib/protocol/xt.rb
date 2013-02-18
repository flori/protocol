module Protocol
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
end
