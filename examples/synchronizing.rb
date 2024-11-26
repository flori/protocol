#!/usr/bin/env ruby

require 'protocol/core'
require 'thread'
require 'tempfile'

class FileMutex
  def initialize
    @tempfile = Tempfile.new 'file-mutex'
  end

  def path
    @tempfile.path
  end

  def lock
    puts "Synchronizing '#{path}'."
    @tempfile.flock File::LOCK_EX
  end

  def unlock
    puts "Unlocking '#{path}'."
    @tempfile.flock File::LOCK_UN
  end

  conform_to Synchronizing
end

FileMutex.conform_to? Synchronizing     # => true
FileMutex.new.conform_to? Synchronizing # => true

# Outputs something like:
#  Synchronizing '...'.
#  Synchronized with '...'..
#  Unlocking '...'.
p mutex = FileMutex.new
mutex.synchronize do
  puts "Synchronized with '#{mutex.path}'."
end

class MemoryMutex
  def initialize
    @mutex = Mutex.new
  end

  def lock
    @mutex.lock
  end

  def unlock
    @mutex.unlock
  end

  conform_to Synchronizing # actually Mutex itself would conform as well ;)
end

p mutex = MemoryMutex.new
mutex.synchronize do
  puts "Synchronized in memory."
end

puts MemoryMutex.conform_to?(Synchronizing).to_s     + ' (true)'
puts MemoryMutex.new.conform_to?(Synchronizing).to_s + ' (true)'

class MyClass
  def initialize
    @mutex = FileMutex.new
  end

  attr_reader :mutex

  def mutex=(mutex)
    Synchronizing =~ mutex
    @mutex = mutex
  end
end

obj = MyClass.new
p obj.mutex # => #<FileMutex:0xb788f9ac @tempfile=#<File:/tmp/file-mutex.26553.2>>
begin
  obj.mutex = Object.new
rescue Protocol::CheckFailed => e
  p e
else
  puts "Should have thrown Protocol::CheckFailed!"
end
p obj.mutex = MemoryMutex.new # => #<MemoryMutex:0xb788f038 @mutex=#<Mutex:0xb788eea8>>
# This works as well:
obj.mutex = Mutex.new
puts Synchronizing.check(Mutex).to_s        + ' (true)'
puts Mutex.conform_to?(Synchronizing).to_s  + ' (true)'
