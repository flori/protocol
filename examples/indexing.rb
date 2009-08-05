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
  puts "Should have thrown Protocol::CheckFailed!"
  rescue Protocol::CheckFailed => e
    p e
  end
end
