
#!/usr/bin/env ruby

require 'protocol/core'

class Person
  def initialize(name, size)
    @name, @size = name, size
  end

  attr_reader :name, :size

  def <=>(other)
    size <=> other.size
  end

  conform_to Comparing
end

goliath = Person.new 'Goliath', 2_60
david = Person.new 'David', 1_40
symbol = Person.new 'The artist formerly known as Prince', 1_40

puts "david < goliath   = #{david < goliath} (true)"
puts "david >= goliath  = #{david >= goliath} (false)"
puts "david == symbol   = #{david == symbol} (true)"

begin
  class NoPerson
    def initialize(name, size)
      @name, @size = name, size
    end

    attr_reader :name, :size

    conform_to Comparing
  end
rescue Protocol::CheckFailed => e
  p e
else
  puts "Should have thrown Protocol::CheckFailed!"
end
