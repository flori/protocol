require 'protocol'

Enumerating = Protocol do
  # Iterate over each element of this Enumerating class and pass it to the
  # _block_.
  def each(&block) end

  include Enumerable
end

begin
  class FailAry
    def initialize
      @ary = [1, 2, 3]
    end

    def each()
    end

    conform_to Enumerating
  end
  puts "Should have thrown Protocol::CheckFailed!"
rescue Protocol::CheckFailed => e
  p e # => "Enumerating#each(0&): expected a block argument for FailAry"
end

class Ary
  def initialize
    @ary = [1, 2, 3]
  end

  def each(&block)
    @ary.each(&block)
  end

  conform_to Enumerating
end

puts Ary.new.map { |x| x * x }.inspect      + " ([1, 4, 9])"
puts Ary.conform_to?(Enumerating).to_s      + " (true)"
puts Ary.new.conform_to?(Enumerating).to_s  + " (true)"

Enumerating.check_failure :none

class FailAry2
  def initialize
    @ary = [1, 2, 3]
  end

  def each() end

  conform_to Enumerating
end

puts FailAry2.conform_to?(Enumerating).to_s     + " (false)"
puts FailAry2.new.conform_to?(Enumerating).to_s + " (false)"
