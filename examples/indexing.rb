#!/usr/bin/env ruby

require 'protocol/core'

class Array
  conform_to Indexing
end

class Hash
  conform_to Indexing
end

begin
  class Proc
    conform_to Indexing
  end
rescue Protocol::CheckFailed => e
  p e
else
  puts "Should have thrown Protocol::CheckFailed!"
end
