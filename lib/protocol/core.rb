require 'protocol'

# Protocol version of the Comparable module, that actually checks, if #<=>
# was implemented by the including (conforming) class.
Comparing = Protocol do
  # Compares _self_ with _other_ and returns -1, 0, or +1 depending on whether
  # _self_ is less than, equal to, or greater than _other_.
  def <=>(other) end

  include Comparable
end

# Protocol version of the Enumerable module, that actually checks, if #each
# was implemented by the including (conforming) class.
Enumerating = Protocol do
  # Iterate over each element of this Enumerating class and pass it to the
  # _block_. Because protocol cannot determine if a block is expected from a
  # C-function, I left it out of the specification for now.
  understand :each

  include Enumerable
end
