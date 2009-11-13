require 'ruby_parser'

module Protocol
  # Parse protocol method definition to derive a Message specification.
  class MethodParser
    class << self
      attr_accessor :__source_cache__

      # Flushes the source cache.
      def flush_source_cache
        __source_cache__.clear
        self
      end
    end
    self.__source_cache__ = {}

    # Create a new MethodParser instance for method +methodname+ of module
    # +modul+. For eigenmethods set +eigenclass+ to true, otherwise bad things
    # will happen.
    def initialize(modul, methodname, eigenclass = false)
      @method = Module === modul ?
        modul.instance_method(methodname) :
        modul.method(methodname)
      compute_args
      parse_method
    end

    # Returns the names of the arguments of the parsed method.
    attr_reader :args

    # Returns the i-th argument (beginning with 0).
    def arg(i)
      @args[i]
    end

    # Returns the kinds of the arguments of the parsed method.
    attr_reader :arg_kinds

    # Returns the i-th kind of an argument (beginning with 0).
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

    private

    def compute_args
      @arity    = @method.arity
      if @method.respond_to?(:parameters)
        parameters = @method.parameters
        @args, @arg_kinds = parameters.map do |kind, name|
          case  kind
          when :req
            [ name, kind ]
          when :opt
            [ name, kind ]
          when :rest
            [ :"*#{name}", kind ]
          when :block
            [ :"&#{name}", kind ]
          end
        end.compact.transpose
      else
        raise NotImplementedError,
          "#{@method.class}#parameters as in ruby version >=1.9.2 is required"
      end
      @args         ||= []
      @arg_kinds    ||= []
    end

    def cached_source(filename)
      cache = self.class.__source_cache__
      unless source = cache[filename]
        begin
          source = IO.readlines(filename)
          cache[filename] = source
        rescue SystemCallError => e
          $DEBUG and warn "Caught #{e.class}: #{e}"
          nil
        end
      end
      source
    end

    def parse_method
      @complex  = false
      filename, lineno = @method.source_location
      if filename
        source = cached_source(filename) or return
        source = source[(lineno - 1)..-1].join
        current = 0
        tree = nil
        parser = RubyParser.new
        while current = source.index('end', current)
          current += 3
          begin
            tree = parser.parse(source[0, current], filename)
            break
          rescue SyntaxError, Racc::ParseError
          end
          parser.reset
        end
        ary = tree.to_a.flatten
        @complex = ary.any? { |node| [ :call, :fcall, :vcall ].include?(node) }
        if ary.index(:yield) and @arg_kinds.last != :block
          @args.push :'&block'
          @arg_kinds.push :block
        end
      end
    end
  end
end
