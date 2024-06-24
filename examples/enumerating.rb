#!/usr/bin/env ruby

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
  p e # => "Enumerating#each(0&): expected a block argument for FailAry"
else
  puts "Should have thrown Protocol::CheckFailed!"
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

class FailAry2
  def initialize
    @ary = [1, 2, 3]
  end

  def each() end

  conform_to Enumerating
end

puts FailAry2.conform_to?(Enumerating).to_s     + " (false)"
puts FailAry2.new.conform_to?(Enumerating).to_s + " (false)"
