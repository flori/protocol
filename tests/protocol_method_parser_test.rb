#!/usr/bin/env ruby

require 'test_helper'

class ProtocolMethodParserTest < Test::Unit::TestCase
  include Protocol

  class A
    def empty
    end

    def none()
    end

    def one_req(a)
    end

    def two_req(a, b)
    end

    def one_req_one_opt(a, b = nil)
    end

    def one_opt(a = nil)
    end

    def two_opt(a = nil, b = nil)
    end

    def one_req_rest(a, *b)
    end

    def one_opt_rest(a = nil, *b)
    end

    def block(&b)
    end

    def one_req_block(a, &b)
    end

    def one_opt_block(a = nil, &b)
    end

    def yield
      yield
    end

    def yield_block(&b)
      yield
    end

    def complex_end
      a = :end
      foo() { }
      a
    end

    def complex
      foo() { }
    end
  end

  def test_args
    m = :empty; mp = MethodParser.new(A, m)
    assert_equal(0, mp.arity, "arity failed for A##{m}")
    assert_equal([ ], mp.args, "args failed for A##{m}")
    assert_equal([ ], mp.arg_kinds, "args failed for A##{m}")
    assert !mp.complex?
    m = :none; mp = MethodParser.new(A, m)
    assert_equal(0, mp.arity, "arity failed for A##{m}")
    assert_equal([ ], mp.args, "args failed for A##{m}")
    assert_equal([ ], mp.arg_kinds, "args failed for A##{m}")
    assert !mp.complex?
    m = :one_req; mp = MethodParser.new(A, m)
    assert_equal(1, mp.arity, "arity failed for A##{m}")
    assert_equal([ :a ], mp.args, "args failed for A##{m}")
    assert_equal([ :req ], mp.arg_kinds, "args failed for A##{m}")
    assert !mp.complex?
    m = :two_req; mp = MethodParser.new(A, m)
    assert_equal(2, mp.arity, "arity failed for A##{m}")
    assert_equal([ :req, :req ], mp.arg_kinds, "args failed for A##{m}")
    assert_equal([ :a, :b ], mp.args, "args failed for A##{m}")
    assert !mp.complex?
    m = :one_req_one_opt; mp = MethodParser.new(A, m)
    assert_equal(-2, mp.arity, "arity failed for A##{m}")
    assert_equal([ :a, :b ], mp.args, "args failed for A##{m}")
    assert_equal([ :req, :opt ], mp.arg_kinds, "args failed for A##{m}")
    assert !mp.complex?
    m = :one_opt; mp = MethodParser.new(A, m)
    assert_equal(-1, mp.arity, "arity failed for A##{m}")
    assert_equal([ :a ], mp.args, "args failed for A##{m}")
    assert_equal([ :opt ], mp.arg_kinds, "args failed for A##{m}")
    assert !mp.complex?
    m = :two_opt; mp = MethodParser.new(A, m)
    assert_equal(-1, mp.arity, "arity failed for A##{m}")
    assert_equal([ :a, :b ], mp.args, "args failed for A##{m}")
    assert_equal([ :opt, :opt ], mp.arg_kinds, "args failed for A##{m}")
    assert !mp.complex?
    m = :one_req_rest; mp = MethodParser.new(A, m)
    assert_equal(-2, mp.arity, "arity failed for A##{m}")
    assert_equal([ :a, :'*b' ], mp.args, "args failed for A##{m}")
    assert_equal([ :req, :rest ], mp.arg_kinds, "args failed for A##{m}")
    assert !mp.complex?
    m = :one_opt_rest; mp = MethodParser.new(A, m)
    assert_equal(-1, mp.arity, "arity failed for A##{m}")
    assert_equal([ :a, :'*b' ], mp.args, "args failed for A##{m}")
    assert_equal([ :opt, :rest ], mp.arg_kinds, "args failed for A##{m}")
    assert !mp.complex?
    m = :block; mp = MethodParser.new(A, m)
    assert_equal(0, mp.arity, "arity failed for A##{m}")
    assert_equal([ :'&b' ], mp.args, "args failed for A##{m}")
    assert_equal([ :block ], mp.arg_kinds, "args failed for A##{m}")
    assert !mp.complex?
    m = :one_req_block; mp = MethodParser.new(A, m)
    assert_equal(1, mp.arity, "arity failed for A##{m}")
    assert_equal([ :a, :'&b' ], mp.args, "args failed for A##{m}")
    assert_equal([ :req, :block ], mp.arg_kinds, "args failed for A##{m}")
    assert !mp.complex?
    m = :one_opt_block; mp = MethodParser.new(A, m)
    assert_equal(-1, mp.arity, "arity failed for A##{m}")
    assert_equal([ :a, :'&b' ], mp.args, "args failed for A##{m}")
    assert_equal([ :opt, :block ], mp.arg_kinds, "args failed for A##{m}")
    assert !mp.complex?
    m = :yield_block; mp = MethodParser.new(A, m)
    assert_equal(0, mp.arity, "arity failed for A##{m}")
    assert_equal([ :'&b' ], mp.args, "args failed for A##{m}")
    assert_equal([ :block ], mp.arg_kinds, "args failed for A##{m}")
    assert !mp.complex?
    m = :yield; mp = MethodParser.new(A, m)
    assert_equal(0, mp.arity, "arity failed for A##{m}")
    assert_equal([ :'&block' ], mp.args, "args failed for A##{m}")
    assert_equal([ :block ], mp.arg_kinds, "args failed for A##{m}")
    assert !mp.complex?
    m = :complex_end; mp = MethodParser.new(A, m)
    assert_equal(0, mp.arity, "arity failed for A##{m}")
    assert_equal([ ], mp.args, "args failed for A##{m}")
    assert_equal([ ], mp.arg_kinds, "args failed for A##{m}")
    assert mp.complex?
    m = :complex; mp = MethodParser.new(A, m)
    assert_equal(0, mp.arity, "arity failed for A##{m}")
    assert_equal([ ], mp.args, "args failed for A##{m}")
    assert_equal([ ], mp.arg_kinds, "args failed for A##{m}")
    assert mp.complex?
  end
end
