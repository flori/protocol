require 'parse_tree'
require 'sexp_processor'

module Protocol
  # Parse protocol method definition to derive a Message specification.
  class MethodParser < SexpProcessor
    # Create a new MethodParser instance for method +methodname+ of module
    # +modul+. For eigenmethods set +eigenclass+ to true, otherwise bad things
    # will happen.
    def initialize(modul, methodname, eigenclass = false)
      super()
      @method = Module === modul ?
        modul.instance_method(methodname) :
        modul.method(methodname)
      self.strict = false
      self.auto_shift_type = true
      @complex      = false
      @first_defn   = true
      @first_block  = true
      @args         = []
      @arg_kinds    = []
      @arity        = @method.arity
      parsed = ParseTree.new.parse_tree_for_method(modul, methodname, eigenclass)
      process parsed
    end

    # Process +exp+, but catch UnsupportedNodeError exceptions and ignore them.
    def process(exp)
      super
    rescue UnsupportedNodeError => ignore
    end

    # Returns the names of the arguments of the parsed method.
    attr_reader :args

    def arg(i)
      @args[i]
    end

    # Returns the names of the arguments of the parsed method.
    attr_reader :arg_kinds

    def arg_kind(i)
      @arg_kinds[i]
    end

    # Returns the arity of the parsed method.
    attr_reader :arity

    # Return true if this protocol method is a complex method, which ought to
    # be called for checking conformance to the protocol.
    def complex?
      @complex
    end

    # Return true if a block argument was detected.
    def block_arg?
      @arg_kinds.last == :block
    end

    # Only consider first the first defn, skip inner method definitions.
    def process_defn(exp)
      if @first_defn
        @first_defn = false
        _name, scope = exp
        process scope
      end
      exp.clear
      s :dummy
    end

    # Remember the argument names in +exp+ in the args attribute.
    def process_args(exp)
      @args.replace exp.select { |x| x.is_a? Symbol }
      @arg_kinds = @args.map { |a| a.to_s[0] == ?* ? :rest : :req }
      if block = exp.find { |x| x.is_a?(Array) and x.first == :block }
        lasgns = block[1..-1].transpose[1]
        i = args.size - 1
        @args.reverse_each do |a|
          exp.first
          l = lasgns.last
          if a == l
            @arg_kinds[i] = :opt
            lasgns.pop
          end
          i -= 1
        end
      end
      exp.clear
      s :dummy
    end

    # Remember if we encounter a block argument.
    def process_block_arg(exp)
      @args.push :"&#{exp.first}"
      @arg_kinds.push :block
      exp.clear
      s :dummy
    end

    # Remember if we encounter a yield keyword.
    def process_yield(exp)
      if @arg_kinds.last != :block
        @args.push :'&block'
        @arg_kinds.push :block
      end
      exp.clear
      s :dummy
    end

    # We only consider the first block in +exp+ (can there be more than one?),
    # and then try to figure out, if this is a complex method or not. Continue
    # processing the +exp+ tree after that.
    def process_block(exp)
      if @first_block
        @first_block = false
        @complex = exp.flatten.any? { |e| [ :call, :fcall, :vcall ].include?(e) }
        exp.each { |e| process e }
      end
      exp.clear
      s :dummy
    end
  end
end
