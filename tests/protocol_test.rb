#!/usr/bin/env ruby

require 'test_helper'

class ProtocolTest < Test::Unit::TestCase
  ProtocolTest_foo = Protocol do
    check_failure :none

    understand :foo
  end

  ProtocolTest_foo_fail = Protocol do
    understand :foo
  end

  ProtocolTest_bar = Protocol do
    understand :bar
  end

  ProtocolTest_foo_bar_1 = Protocol do
    include ProtocolTest::ProtocolTest_foo
    understand :bar
  end

  ProtocolTest_foo_bar_1_fail = Protocol do
    include ProtocolTest::ProtocolTest_foo
    understand :bar
  end

  ProtocolTest_foo_bar_2 = Protocol do
    include ProtocolTest::ProtocolTest_foo
    include ProtocolTest::ProtocolTest_bar
  end

  ProtocolTest_foo_bar_2_fail = Protocol do
    check_failure :error

    include ProtocolTest::ProtocolTest_foo
    include ProtocolTest::ProtocolTest_bar
  end

  ProtocolTestArgs = Protocol do
    understand :bar, 2
    understand :baz, 3
    understand :foo, -1
  end

  ProtocolTestArgsOverwritten = Protocol do
    include ProtocolTest::ProtocolTestArgs

    def bar(a, b, c)
    end

    def foo(a)
    end
  end

  ProtocolTestBlock = Protocol do
    def foo(x, &block)
    end
  end

  ProtocolTestPartial = Protocol do
    check_failure :none

    implementation

    def map(&block)
      result = []
      each { |x| result << block.call(x) }
      result
    end

    specification

    def each(&block) end
  end

  ProtocolTestPartial_fail = Protocol do
    check_failure :error

    def each(&block) end

    implementation

    def map(&block)
      result = []
      each { |x| result << block.call(x) }
      result
    end
  end

  ProtocolTestWrapMethodPassedFoo = Protocol do
    def foo(foo, *rest) end
  end

  ProtocolTestWrapMethodPassedBar = Protocol do
    def bar() end
  end

  ProtocolTestWrapMethod = Protocol do
    def foo_bar(foo, bar)
      ::ProtocolTest::ProtocolTestWrapMethodPassedFoo =~ foo
      ::ProtocolTest::ProtocolTestWrapMethodPassedBar =~ bar
    end
  end

  ProtocolTestPostcondition = Protocol do
    def foo_bar(foo, bar)
      postcondition { foo + bar == result }
    end

    def foo_bars(foo, *bars)
      postcondition { bars.unshift(foo) == result }
    end
  end

  ProtocolTestPrecondition = Protocol do
    def foo_bar(foo, bar)
      precondition { foo == 5 }
      precondition { bar == 7 }
    end
  end

  class MyClass
    def one_with_block(foo, &block) end
  end

  ProtocolTestInheritance = Protocol do
    inherit ProtocolTest::MyClass, :one_with_block
  end

  ProtocolTestInheritanceC = Protocol do
    inherit ::Array, :each, true
  end

  def test_define_protocol
    foo_protocol = Protocol do
      understand :foo
      understand :bar
    end
    assert_kind_of Protocol::ProtocolModule, foo_protocol
    assert_raises(Protocol::SpecificationError) do
      foo2_protocol = Protocol do
        understand :foo
        understand :foo
      end
    end
    foo3_protocol = Protocol do
      understand :foo, 1
      understand :bar
    end
    assert_kind_of Protocol::ProtocolModule, foo3_protocol
    assert_equal foo_protocol[:bar], foo3_protocol[:bar]
    assert_not_same foo_protocol[:bar], foo3_protocol[:bar]
    assert_not_equal foo_protocol[:foo], foo3_protocol[:foo]
    assert_not_same foo_protocol[:foo], foo3_protocol[:foo]
    assert foo_protocol.understand?(:foo)
    assert foo_protocol.understand?(:bar)
    assert !foo_protocol.understand?(:baz)
    assert foo3_protocol.understand?(:foo)
    assert foo3_protocol.understand?(:foo, 1)
    assert foo3_protocol.understand?(:bar)
    assert !foo3_protocol.understand?(:baz)
    assert_equal [ foo3_protocol[:bar] ], foo3_protocol.grep(/^b/)
  end

  def test_simple_without_fail
    c1 = Class.new do
      def foo; end

      conform_to ProtocolTest_foo
    end
    assert c1.conform_to?(ProtocolTest_foo)
    assert c1.new.conform_to?(ProtocolTest_foo)
    assert !c1.conform_to?(ProtocolTest_foo_bar_1)
    assert !c1.new.conform_to?(ProtocolTest_foo_bar_1)
    assert !c1.conform_to?(ProtocolTest_bar)
    assert !c1.new.conform_to?(ProtocolTest_bar)
    assert_equal 2, ProtocolTest_foo_bar_1.check_failures(Object).size
    assert_equal 2, ProtocolTest_foo_bar_1.check_failures(Object.new).size
    assert_equal 1, ProtocolTest_foo_bar_1.check_failures(c1).size
    assert_equal 1, ProtocolTest_foo_bar_1.check_failures(c1.new).size

    c2 = Class.new do
      conform_to ProtocolTest_foo
    end
    assert !c2.conform_to?(ProtocolTest_foo)
    assert !c2.new.conform_to?(ProtocolTest_foo)
    assert !c2.conform_to?(ProtocolTest_foo_bar_1)
    assert !c2.new.conform_to?(ProtocolTest_foo_bar_1)
    assert !c2.conform_to?(ProtocolTest_bar)
    assert !c2.new.conform_to?(ProtocolTest_bar)
  end

  def test_simple_with_fail
    c1 = Class.new do
      def foo; end

      conform_to ProtocolTest_foo_fail
    end
    assert c1.conform_to?(ProtocolTest_foo_fail)
    assert c1.new.conform_to?(ProtocolTest_foo_fail)
    assert !c1.conform_to?(ProtocolTest_foo_bar_1)
    assert !c1.new.conform_to?(ProtocolTest_foo_bar_1)
    assert !c1.conform_to?(ProtocolTest_bar)
    assert !c1.new.conform_to?(ProtocolTest_bar)

    begin
      c2 = Class.new do
        conform_to ProtocolTest_foo_fail
      end
      assert(false)
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
  end

  def test_inclusion1_with_fail
    begin
      c = Class.new do
        def bar; end
        conform_to ProtocolTest_foo_bar_1_fail
      end
      assert(false)
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
  end

  def test_inclusion2
    c = Class.new do
      def foo; end
      def bar; end
      conform_to ProtocolTest_foo_bar_1
    end
    assert(true)
    assert c.conform_to?(ProtocolTest_foo_bar_1)
  end

  def test_inclusion3
    c = Class.new do
      def bar; end
      conform_to ProtocolTest_foo_bar_2
    end
    assert !c.conform_to?(ProtocolTest_foo_bar_2)
    assert(false)
  rescue Protocol::CheckFailed
    assert(true)
  rescue
    assert(false)
  end

  # Check argument arity

  def test_arity1
    c = Class.new do
      def bar(x, y) x + y end
      def foo(*x) x end
      def baz(x, y, z) Math.sqrt(x * x + y * y + z * z) end

      conform_to ProtocolTestArgs
    end
    assert c.conform_to?(ProtocolTestArgs)
    assert c.new.conform_to?(ProtocolTestArgs)
  rescue
    assert(false)
  end

  def test_arity2
    c = Class.new do
      def bar(x, y) x + y end
      def baz(x, y, z) Math.sqrt(x * x + y * y + z * z) end
      def foo(x) x end

      conform_to ProtocolTestArgs
    end
    assert(false)
  rescue Protocol::CheckFailed
    assert(true)
  rescue
    assert(false)
  end

  def test_arity3
    c = Class.new do
      def bar(x, y) x + y end
      def baz(x, y, z) Math.sqrt(x * x + y * y + z * z) end
      def foo(x) x end

      conform_to ProtocolTestArgs
    end
  rescue Protocol::CheckFailed
    assert(true)
  rescue
    assert(false)
  end

  def test_block
    begin
      c1 = Class.new do
        def foo(x) end

        conform_to ProtocolTestBlock
      end
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
    c1b = Class.new do
      def foo(x) end
    end
    assert !c1b.new.conform_to?(ProtocolTestBlock)
    begin
      c2 = Class.new do
        def foo(x, &block) block[x] end

        conform_to ProtocolTestBlock
      end
      assert(true)
    rescue Protocol::CheckFailed
      assert(false)
    rescue
      assert(false)
    end
    begin
      c3 = Class.new do
        def foo(x) yield x end

        conform_to ProtocolTestBlock
      end
      assert(true)
    rescue Protocol::CheckFailed
      assert(false)
    rescue
      assert(false)
    end
    obj = Object.new
    assert !obj.conform_to?(ProtocolTestBlock)
    def obj.foo(x, &b) end
    assert obj.conform_to?(ProtocolTestBlock)
  end

  def test_partial_without_fail
    c1 = Class.new do
      def each(&block)
        (1..3).each(&block)
        self
      end

      conform_to ProtocolTestPartial
    end
    obj = c1.new
    assert c1.conform_to?(ProtocolTestPartial)
    assert obj.conform_to?(ProtocolTestPartial)
    assert_equal [ 1, 4, 9], obj.map { |x| x * x }
    assert_equal obj, obj.each { |x| x * x }

    c2 = Class.new do
      conform_to ProtocolTestPartial
    end
    assert !c2.conform_to?(ProtocolTestPartial)
    assert !c2.new.conform_to?(ProtocolTestPartial)
    assert_raises(NoMethodError) { c2.new.map { |x| x * x } }
    assert_equal obj, obj.each { |x| x * x }
  end

  def test_partial_with_fail
    c1 = Class.new do
      def each(&block)
        (1..3).each(&block)
        self
      end

      conform_to ProtocolTestPartial_fail
    end
    obj = c1.new
    assert c1.conform_to?(ProtocolTestPartial)
    assert obj.conform_to?(ProtocolTestPartial)
    assert_equal [ 1, 4, 9], obj.map { |x| x * x }
    assert_equal obj, obj.each { |x| x * x }

    begin
      c2 = Class.new do
        conform_to ProtocolTestPartial_fail
      end
      assert(false)
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
  end

  def test_overwrite
    c = Class.new do
      def bar(x, y, z) x + y + z end
      def baz(x, y, z) Math.sqrt(x * x + y * y + z * z) end
      def foo(x) x end

      conform_to ProtocolTestArgsOverwritten
    end
    assert c.conform_to?(ProtocolTestArgsOverwritten)
  rescue Protocol::CheckFailed
    assert(false)
  rescue
    assert(false)
  end

  def test_messages
    assert_equal %w[bar baz foo], ProtocolTestArgs.messages.map { |x| x.name }
    assert_equal [2, 3, -1], ProtocolTestArgs.messages.map { |x| x.arity }
    assert_equal "ProtocolTest::ProtocolTestArgs#bar(2), ProtocolTest::ProtocolTestArgs#baz(3), ProtocolTest::ProtocolTestArgs#foo(-1)", ProtocolTestArgs.to_s
    assert_equal %w[bar baz foo], ProtocolTestArgsOverwritten.messages.map { |x| x.name }
    assert_equal [3, 3, 1], ProtocolTestArgsOverwritten.messages.map { |x| x.arity }
    assert_equal "ProtocolTest::ProtocolTestArgsOverwritten#bar(3), ProtocolTest::ProtocolTestArgs#baz(3), ProtocolTest::ProtocolTestArgsOverwritten#foo(1)", ProtocolTestArgsOverwritten.to_s
  end

  def test_wrapped_method
    begin
      c1 = Class.new do
        def foo(foo, *rest) foo end

        conform_to ProtocolTestWrapMethodPassedFoo
      end
      assert(true)
    rescue Protocol::CheckFailed
      assert(false)
    rescue
      assert(false)
    end
    begin
      c2 = Class.new do
        def bar() :bar end

        conform_to ProtocolTestWrapMethodPassedBar
      end
      assert(true)
    rescue Protocol::CheckFailed
      assert(false)
    rescue
      assert(false)
    end
    begin
      c3 = Class.new do
        def foo_bar(foo, bar)
          [ foo.foo(:foo, :baz), bar.bar ]
        end

        conform_to ProtocolTestWrapMethod
      end
      assert(true)
    rescue Protocol::CheckFailed
      assert(false)
    rescue
      assert(false)
    end
    begin
      assert_equal [:foo, :bar], c3.new.foo_bar(c1.new, c2.new)
    rescue Protocol::CheckFailed
      assert(false)
    rescue
      assert(false)
    end
    begin
      c3.new.foo_bar c1.new, c1.new
      assert(false)
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
  end

  def test_precondition
    begin
      c1 = Class.new do
        def foo_bar(foo, bar)
          foo + bar
        end

        conform_to ProtocolTestPrecondition
      end
      assert(true)
    rescue Protocol::CheckFailed
      assert(false)
    rescue
      assert(false)
    end
    assert_equal 5 + 7, c1.new.foo_bar(5, 7)
    assert_raises(Protocol::PreconditionCheckError) { c1.new.foo_bar(5, 8) }
  end

  def test_postcondition
    begin
      c1 = Class.new do
        def foo_bar(foo, bar)
          foo + bar
        end

        def foo_bars(foo, *bars)
          bars.unshift foo
        end

        conform_to ProtocolTestPostcondition
      end
      c2 = Class.new do
        def foo_bar(foo, bar)
          foo + bar + 1
        end

        def foo_bars(foo, *bars)
          bars.unshift foo
        end

        conform_to ProtocolTestPostcondition
      end
      assert(true)
    rescue Protocol::CheckFailed
      assert(false)
    rescue
      assert(false)
    end
    assert_equal [5, 7], c1.new.foo_bars(5, 7)
    assert_equal 5 + 7, c1.new.foo_bar(5, 7)
    assert_equal [5, 7], c2.new.foo_bars(5, 7)
    assert_raises(Protocol::PostconditionCheckError) { c2.new.foo_bar(5, 7) }
    o1 = Object.new
    def o1.foo_bar(foo, bar)
      foo + bar
    end
    def o1.foo_bars(foo, *bars)
      bars.unshift foo
    end
    assert ProtocolTestPostcondition =~ o1
    assert_equal [5, 7], o1.foo_bars(5, 7)
    assert_equal 5 + 7, o1.foo_bar(5, 7)
    o2 = Object.new
    def o2.foo_bar(foo, bar)
      foo + bar + 1
    end
    def o2.foo_bars(foo, *bars)
      bars.unshift foo
    end
    assert ProtocolTestPostcondition =~ o2
    assert_equal [5, 7], o2.foo_bars(5, 7)
    assert_raises(Protocol::PostconditionCheckError) { o2.foo_bar(5, 7) }
  end

  def test_inheritance
    begin
      c1 = Class.new do
        conform_to ProtocolTestInheritance
      end
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
    begin
      c2 = Class.new do
        def one_with_block() end
        conform_to ProtocolTestInheritance
      end
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
    begin
      c3 = Class.new do
        def one_with_block(foo) end
        conform_to ProtocolTestInheritance
      end
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
    begin
      c4 = Class.new do
        def one_with_block(foo, &block) end
        conform_to ProtocolTestInheritance
      end
      assert(true)
    rescue Protocol::CheckFailed
      assert(false)
    rescue
      assert(false)
    end
    begin
      c5 = Class.new do
        def each() end
        conform_to ProtocolTestInheritanceC
      end
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
    begin
      c6 = Class.new do
        def each(&block) end
        conform_to ProtocolTestInheritanceC
      end
      assert(true)
    rescue Protocol::CheckFailed
      assert(false)
    rescue
      assert(false)
    end
  end
end
