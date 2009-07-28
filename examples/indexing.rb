require 'protocol'

Indexing = Protocol {
  check_failure :error

  understand :[]

  understand :[]=
}

if $0 == __FILE__
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
    e.to_s # => "Indexing#[]=(): method '[]=' not implemented in Proc"
  end
end
