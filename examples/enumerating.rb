require 'protocol/core'

begin
  class FailAry
    def initialize
      @ary = [1, 2, 3]
    end

    def each()
    end

    conform_to Enumerating
  end
rescue Protocol::CheckFailed => e
  e.to_s # => "Enumerating#each(0&): expected a block argument for FailAry"
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

Ary.new.map { |x| x * x }        # => [1, 4, 9]
Ary.conform_to?(Enumerating)     # => true
Ary.new.conform_to?(Enumerating) # => true

Enumerating.check_failure :none

class FailAry2
  def initialize
    @ary = [1, 2, 3]
  end

  def each() end

  conform_to Enumerating
end

FailAry2.conform_to?(Enumerating)     # => false
FailAry2.new.conform_to?(Enumerating) # => false
