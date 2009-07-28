require 'protocol'

# Classical Stack example.
StackProtocol = Protocol do
  def push(x)
    postcondition { top == x }
    postcondition { result == myself }
  end

  def top() end

  def size() end

  def empty?()
    postcondition { size == 0 ? result : !result }
  end

  def pop()
    s = size
    precondition { not empty? }
    postcondition { size == s - 1 }
  end
end

class S
  def initialize
    @ary = []
  end

  def push(x)
    @ary.push x
    self
  end

  def top
    @ary.last
  end

  def size()
    @ary.size
  end

  def empty?
    @ary.empty?
  end

  def pop()
    @ary.pop
  end

  conform_to StackProtocol
end

if $0 == __FILE__
  s = S.new
  s.top # => nil
  s.empty? # => true
  s.size # => 0
  begin
    s.pop
  rescue Protocol::CheckError => e
    e # => #<Protocol::PreconditionCheckError: StackProtocol#empty?(0): precondition failed for S>
  end
  s.empty? # => true
  s.push 2
  s.empty? # => false
  s.size # => 1
  s.top # => 2
  s.push 4
  s.top # => 4
  s.size # => 2
  s.pop # => 4
  s.top # => 2
  s.size # => 1
end
