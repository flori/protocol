# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
    s.name = 'protocol'
    s.version = '0.9.0'
    s.files = ["CHANGES", "COPYING", "Rakefile", "VERSION", "benchmarks", "benchmarks/data", "benchmarks/method_parser.rb", "doc-main.txt", "examples", "examples/comparing.rb", "examples/enumerating.rb", "examples/game.rb", "examples/hello_world_patternitis.rb", "examples/indexing.rb", "examples/locking.rb", "examples/queue.rb", "examples/stack.rb", "install.rb", "lib", "lib/protocol", "lib/protocol.rb", "lib/protocol/core.rb", "lib/protocol/method_parser", "lib/protocol/method_parser/parse_tree.rb", "lib/protocol/method_parser/ruby_parser.rb", "lib/protocol/version.rb", "make_doc.rb", "protocol.gemspec", "tests", "tests/test_protocol.rb", "tests/test_protocol_method_parser.rb"]
    s.summary = 'Method Protocols for Ruby Classes'
    s.description = <<EOT
This library offers an implementation of protocols against which you can check
the conformity of your classes or instances of your classes. They are a bit
like Java Interfaces, but as mixin modules they can also contain already
implemented methods. Additionaly you can define preconditions/postconditions
for methods specified in a protocol.
EOT

    s.require_path = 'lib'
    s.add_dependency 'ParseTree', '~> 3.0'
    s.add_dependency 'ruby_parser', '~> 2.0'

    s.has_rdoc = true
    s.rdoc_options << '--main' << 'doc-main.txt'
    s.extra_rdoc_files << 'doc-main.txt'
    s.test_files << 'tests/test_protocol.rb'

    s.author = "Florian Frank"
    s.email = "flori@ping.de"
    s.homepage = "http://flori.github.com/protocol"
    s.rubyforge_project = "protocol"
  end
