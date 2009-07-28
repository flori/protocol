#!/usr/bin/env ruby

require 'test/unit'
require 'protocol'

class TestProtocol < Test::Unit::TestCase
  TestProtocol_foo = Protocol do
    check_failure :none

    understand :foo
  end

  TestProtocol_foo_fail = Protocol do
    understand :foo
  end

  TestProtocol_bar = Protocol do
    understand :bar
  end

  TestProtocol_foo_bar_1 = Protocol do
    include TestProtocol_foo
    understand :bar
  end

  TestProtocol_foo_bar_1_fail = Protocol do
    include TestProtocol_foo
    understand :bar
  end

  TestProtocol_foo_bar_2 = Protocol do
    include TestProtocol_foo
    include TestProtocol_bar
  end

  TestProtocol_foo_bar_2_fail = Protocol do
    check_failure :error

    include TestProtocol_foo
    include TestProtocol_bar
  end

  TestProtocolArgs = Protocol do
    understand :bar, 2
    understand :baz, 3
    understand :foo, -1
  end

  TestProtocolArgsOverwritten = Protocol do
    include TestProtocolArgs

    def bar(a, b, c)
    end
    
    def foo(a)
    end
  end

  TestProtocolBlock = Protocol do
    def foo(x, &block)
    end
  end

  TestProtocolPartial = Protocol do
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

  TestProtocolPartial_fail = Protocol do
    check_failure :error

    def each(&block) end

    implementation

    def map(&block)
      result = []
      each { |x| result << block.call(x) }
      result
    end
  end

  TestProtocolWrapMethodPassedFoo = Protocol do
    def foo(foo, *rest) end
  end

  TestProtocolWrapMethodPassedBar = Protocol do
    def bar() end
  end

  TestProtocolWrapMethod = Protocol do
    def foo_bar(foo, bar)
      TestProtocolWrapMethodPassedFoo =~ foo
      TestProtocolWrapMethodPassedBar =~ bar
    end
  end

  TestProtocolPostcondition = Protocol do
    def foo_bar(foo, bar)
      postcondition { foo + bar == result }
    end

    def foo_bars(foo, *bars)
      postcondition { bars.unshift(foo) == result }
    end
  end

  TestProtocolPrecondition = Protocol do
    def foo_bar(foo, bar)
      precondition { foo == 5 }
      precondition { bar == 7 }
    end
  end

  class MyClass
    def one_with_block(foo, &block) end
  end

  TestProtocolInheritance = Protocol do
    inherit MyClass, :one_with_block
  end

  TestProtocolInheritanceC = Protocol do
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

      conform_to TestProtocol_foo
    end
    assert c1.conform_to?(TestProtocol_foo)
    assert c1.new.conform_to?(TestProtocol_foo)
    assert !c1.conform_to?(TestProtocol_foo_bar_1)
    assert !c1.new.conform_to?(TestProtocol_foo_bar_1)
    assert !c1.conform_to?(TestProtocol_bar)
    assert !c1.new.conform_to?(TestProtocol_bar)
    assert_equal 2, TestProtocol_foo_bar_1.check_failures(Object).size
    assert_equal 2, TestProtocol_foo_bar_1.check_failures(Object.new).size
    assert_equal 1, TestProtocol_foo_bar_1.check_failures(c1).size
    assert_equal 1, TestProtocol_foo_bar_1.check_failures(c1.new).size

    c2 = Class.new do
      conform_to TestProtocol_foo
    end
    assert !c2.conform_to?(TestProtocol_foo)
    assert !c2.new.conform_to?(TestProtocol_foo)
    assert !c2.conform_to?(TestProtocol_foo_bar_1)
    assert !c2.new.conform_to?(TestProtocol_foo_bar_1)
    assert !c2.conform_to?(TestProtocol_bar)
    assert !c2.new.conform_to?(TestProtocol_bar)
  end

  def test_simple_with_fail
    c1 = Class.new do
      def foo; end

      conform_to TestProtocol_foo_fail
    end
    assert c1.conform_to?(TestProtocol_foo_fail)
    assert c1.new.conform_to?(TestProtocol_foo_fail)
    assert !c1.conform_to?(TestProtocol_foo_bar_1)
    assert !c1.new.conform_to?(TestProtocol_foo_bar_1)
    assert !c1.conform_to?(TestProtocol_bar)
    assert !c1.new.conform_to?(TestProtocol_bar)

    begin
      c2 = Class.new do
        conform_to TestProtocol_foo_fail
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
        conform_to TestProtocol_foo_bar_1_fail
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
      conform_to TestProtocol_foo_bar_1
    end
    assert(true)
    assert c.conform_to?(TestProtocol_foo_bar_1)
  end

  def test_inclusion3
    c = Class.new do
      def bar; end
      conform_to TestProtocol_foo_bar_2
    end
    assert !c.conform_to?(TestProtocol_foo_bar_2)
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

      conform_to TestProtocolArgs
    end
    assert c.conform_to?(TestProtocolArgs)
    assert c.new.conform_to?(TestProtocolArgs)
  rescue
    assert(false)
  end

  def test_arity2
    c = Class.new do
      def bar(x, y) x + y end
      def baz(x, y, z) Math.sqrt(x * x + y * y + z * z) end
      def foo(x) x end

      conform_to TestProtocolArgs
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

      conform_to TestProtocolArgs
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

        conform_to TestProtocolBlock
      end
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
    c1b = Class.new do
      def foo(x) end
    end
    assert !c1b.new.conform_to?(TestProtocolBlock)
    begin
      c2 = Class.new do
        def foo(x, &block) block[x] end

        conform_to TestProtocolBlock
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

        conform_to TestProtocolBlock
      end
      assert(true)
    rescue Protocol::CheckFailed
      assert(false)
    rescue
      assert(false)
    end
    obj = Object.new
    assert !obj.conform_to?(TestProtocolBlock)
    def obj.foo(x, &b) end
    assert obj.conform_to?(TestProtocolBlock)
  end

  def test_partial_without_fail
    c1 = Class.new do
      def each(&block)
        (1..3).each(&block)
        self
      end

      conform_to TestProtocolPartial
    end
    obj = c1.new
    assert c1.conform_to?(TestProtocolPartial)
    assert obj.conform_to?(TestProtocolPartial)
    assert_equal [ 1, 4, 9], obj.map { |x| x * x }
    assert_equal obj, obj.each { |x| x * x }

    c2 = Class.new do
      conform_to TestProtocolPartial
    end
    assert !c2.conform_to?(TestProtocolPartial)
    assert !c2.new.conform_to?(TestProtocolPartial)
    assert_raises(NoMethodError) { c2.new.map { |x| x * x } }
    assert_equal obj, obj.each { |x| x * x }
  end

  def test_partial_with_fail
    c1 = Class.new do
      def each(&block)
        (1..3).each(&block)
        self
      end

      conform_to TestProtocolPartial_fail
    end
    obj = c1.new
    assert c1.conform_to?(TestProtocolPartial)
    assert obj.conform_to?(TestProtocolPartial)
    assert_equal [ 1, 4, 9], obj.map { |x| x * x }
    assert_equal obj, obj.each { |x| x * x }

    begin
      c2 = Class.new do
        conform_to TestProtocolPartial_fail
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

      conform_to TestProtocolArgsOverwritten
    end
    assert c.conform_to?(TestProtocolArgsOverwritten)
  rescue Protocol::CheckFailed
    assert(false)
  rescue
    assert(false)
  end

  def test_messages
    assert_equal %w[bar baz foo], TestProtocolArgs.messages.map { |x| x.name }
    assert_equal [2, 3, -1], TestProtocolArgs.messages.map { |x| x.arity }
    assert_equal "TestProtocol::TestProtocolArgs#bar(2), TestProtocol::TestProtocolArgs#baz(3), TestProtocol::TestProtocolArgs#foo(-1)", TestProtocolArgs.to_s
    assert_equal %w[bar baz foo], TestProtocolArgsOverwritten.messages.map { |x| x.name }
    assert_equal [3, 3, 1], TestProtocolArgsOverwritten.messages.map { |x| x.arity }
    assert_equal "TestProtocol::TestProtocolArgsOverwritten#bar(3), TestProtocol::TestProtocolArgs#baz(3), TestProtocol::TestProtocolArgsOverwritten#foo(1)", TestProtocolArgsOverwritten.to_s
  end

  def test_wrapped_method
    begin
      c1 = Class.new do
        def foo(foo, *rest) foo end

        conform_to TestProtocolWrapMethodPassedFoo
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

        conform_to TestProtocolWrapMethodPassedBar
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

        conform_to TestProtocolWrapMethod
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

        conform_to TestProtocolPrecondition
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

        conform_to TestProtocolPostcondition
      end
      c2 = Class.new do
        def foo_bar(foo, bar)
          foo + bar + 1
        end

        def foo_bars(foo, *bars)
          bars.unshift foo
        end

        conform_to TestProtocolPostcondition
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
    assert TestProtocolPostcondition =~ o1
    assert_equal [5, 7], o1.foo_bars(5, 7)
    assert_equal 5 + 7, o1.foo_bar(5, 7)
    o2 = Object.new
    def o2.foo_bar(foo, bar)
      foo + bar + 1
    end
    def o2.foo_bars(foo, *bars)
      bars.unshift foo
    end
    assert TestProtocolPostcondition =~ o2
    assert_equal [5, 7], o2.foo_bars(5, 7)
    assert_raises(Protocol::PostconditionCheckError) { o2.foo_bar(5, 7) }
  end

  def test_inheritance
    begin
      c1 = Class.new do
        conform_to TestProtocolInheritance
      end
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
    begin
      c2 = Class.new do
        def one_with_block() end
        conform_to TestProtocolInheritance
      end
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
    begin
      c3 = Class.new do
        def one_with_block(foo) end
        conform_to TestProtocolInheritance
      end
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
    begin
      c4 = Class.new do
        def one_with_block(foo, &block) end
        conform_to TestProtocolInheritance
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
        conform_to TestProtocolInheritanceC
      end
    rescue Protocol::CheckFailed
      assert(true)
    rescue
      assert(false)
    end
    begin
      c6 = Class.new do
        def each(&block) end
        conform_to TestProtocolInheritanceC
      end
      assert(true)
    rescue Protocol::CheckFailed
      assert(false)
    rescue
      assert(false)
    end
  end
end
  # vim: set et sw=2 ts=2:
