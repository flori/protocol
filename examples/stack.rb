#!/usr/bin/env ruby

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

s = S.new
puts s.top.inspect + " (nil)"
puts s.empty?.to_s + " (true)"
puts s.size.to_s   + " (0)"
begin
  s.pop
rescue Protocol::CheckError => e
  p e # => #<Protocol::PreconditionCheckError: StackProtocol#empty?(0): precondition failed for S>
end
puts s.empty?.to_s  + " (true)"
s.push 2
puts s.empty?.to_s  + " (false)"
puts s.size.to_s    + " (1)"
puts s.top.to_s     + " (2)"
s.push 4
puts s.top.to_s     + " (4)"
puts s.size.to_s    + " (2)"
puts s.pop.to_s     + " (4)"
puts s.top.to_s     + " (2)"
puts s.size.to_s    + " (1)"
