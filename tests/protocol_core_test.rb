#!/usr/bin/env ruby

require 'test_helper'
require 'protocol/core'

class ProtocolCoreTest < Test::Unit::TestCase
  def test_comparing_numeric
    assert Numeric.conform_to?(Comparing)
  end

  def test_comparing_complex
    assert_false BasicObject.conform_to?(Comparing)
  end

  def test_comparing_array
    assert Array.conform_to?(Comparing)
  end

  def test_comparing_string
    assert String.conform_to?(Comparing)
  end

  def test_enumerating_array
    assert Array.conform_to?(Enumerating)
  end

  def test_enumerating_float
    assert_false Float.conform_to?(Enumerating)
  end

  def test_enumerating_hash
    assert Hash.conform_to?(Enumerating)
  end

  def test_indexing_array
    assert Array.conform_to?(Indexing)
  end

  def test_indexing_proc
    assert_false Proc.conform_to?(Indexing)
  end

  def test_indexing_hash
    assert Hash.conform_to?(Indexing)
  end

  def test_sychronizing_mutex
    assert Mutex.conform_to?(Synchronizing)
  end

  def test_sychronizing_hash
    assert_false Hash.conform_to?(Synchronizing)
  end

  def test_my_synchronizer
    s = Class.new do
      def initialize
        @lock = false
      end

      def lock
        @lock = true
      end

      def locked?
        @lock
      end

      def unlock
        @lock = false
      end

      conform_to Synchronizing
    end.new
    assert_false s.locked?
    s.synchronize { assert s.locked? }
    assert_false s.locked?
  end
end
