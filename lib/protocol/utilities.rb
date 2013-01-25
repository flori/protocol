module Protocol
  # A module for some Utility methods.
  module Utilities
    module_function

    # This Method tries to find the first module that implements the method
    # named +methodname+ in the array of +ancestors+. If this fails nil is
    # returned.
    def find_method_module(methodname, ancestors)
      methodname = methodname.to_s
      ancestors.each do |a|
        begin
          a.instance_method(methodname)
          return a
        rescue NameError
        end
      end
      nil
    end
  end
end
