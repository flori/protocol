#!/usr/bin/env ruby

require 'bullshit'
require 'protocol'

class MethodParserBenchmark < Bullshit::RepeatCase
  include Protocol

  class Foo
    def foo(a, b = nil, *c)
      yield
    end
  end

  warmup              yes

  iterations          500

  truncate_data do
    alpha_level 0.05
    window_size 10
    slope_angle 0.003
  end

  output_dir File.join(File.dirname(__FILE__), 'data')
  data_file  yes
  histogram  yes

  autocorrelation do
    alpha_level 0.05
    max_lags    50
    file        yes
  end

  def benchmark_standard
    @mp = MethodParser.new(Foo, :foo)
  end

  def after_standard
    @mp.args == [ :a, :b, :'*c', :'&block' ] or raise "wrong result"
  end

  def benchmark_nocache
    @mp = MethodParser.new(Foo, :foo)
  end

  def after_nocache
    @mp.args == [ :a, :b, :'*c', :'&block' ] or raise "wrong result"
    MethodParser.flush_source_cache
  end
end
