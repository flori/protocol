require 'protocol'

# Queue + Observer example.
ObserverProtocol = Protocol do
  def after_enq(q)
    s = q.size
    postcondition { q.size == s }
  end

  def after_deq(q)
    s = q.size
    postcondition { q.size == s }
  end
end

class O
  def after_enq(q)
    puts "Enqueued."
  end

  def after_deq(q)
    puts "Dequeued."
  end

  conform_to ObserverProtocol
end

class SneakyO
  def after_enq(q)
    puts "Enqueued."
    q.deq
  end

  def after_deq(q)
    puts "Dequeued."
  end

  conform_to ObserverProtocol
end

QueueProtocol = Protocol do
  def observer=(o)
    ObserverProtocol =~ o
  end

  def enq(x)
    postcondition { not empty? }
    postcondition { result == myself }
  end

  def size() end

  def first()
    postcondition { (size == 0) == (result == nil) }
  end

  def deq()
    precondition { size > 0 }
  end

  def empty?()
    postcondition { (size == 0) == result }
  end
end

class Q
  def initialize
    @ary = []
    @o = nil
  end

  def observer=(o)
    @o = o
  end

  def enq(x)
    @ary.push x
    @o and @o.after_enq(self)
    self
  end

  def size()
    @ary.size
  end

  def first()
    @ary.first
  end

  def empty?
    @ary.empty?
  end

  def deq()
    r = @ary.shift
    @o and @o.after_deq(self)
    r
  end

  conform_to QueueProtocol
end

def should_be(a1, a2)
  puts "#{a1.inspect} (#{a2.inspect})"
end

q = Q.new
q.observer = O.new
should_be q.empty?, true
begin
  q.deq
rescue Protocol::CheckError => e
  p e
end
should_be q.empty?, true
should_be q.size, 0
should_be q.first, nil
q.enq 2
should_be q.empty?, false
should_be q.size, 1
should_be q.first, 2
q.enq 2
should_be q.size, 2
should_be q.deq, 2
should_be q.first, 2
should_be q.size, 1

q = Q.new
q.observer = O.new
should_be q.empty?, true
begin
  q.deq
  puts "Should have thrown Protocol::CheckFailed!"
rescue Protocol::CheckError => e
  p e
end
should_be q.empty?, true
should_be q.size, 0
should_be q.first, nil
q.enq 2
should_be q.empty?, false
should_be q.size, 1
should_be q.first, 2
q.enq 2
should_be q.size, 2
should_be q.deq, 2
should_be q.first, 2
should_be q.size, 1
q.observer = SneakyO.new
should_be q.deq, 2
should_be q.empty?, true
begin
  q.enq 7
  puts "Should have thrown Protocol::CheckFailed!"
rescue Protocol::CheckError => e
  p e
end
