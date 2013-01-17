# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "protocol"
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Florian Frank"]
  s.date = "2013-01-17"
  s.description = "This library offers an implementation of protocols against which you can check\nthe conformity of your classes or instances of your classes. They are a bit\nlike Java Interfaces, but as mixin modules they can also contain already\nimplemented methods. Additionaly you can define preconditions/postconditions\nfor methods specified in a protocol.\n"
  s.email = "flori@ping.de"
  s.extra_rdoc_files = ["README.rdoc", "lib/protocol.rb", "lib/protocol/core.rb", "lib/protocol/method_parser/ruby_parser.rb", "lib/protocol/version.rb"]
  s.files = [".gitignore", "CHANGES", "COPYING", "Gemfile", "README.rdoc", "Rakefile", "VERSION", "benchmarks/data/.keep", "benchmarks/method_parser.rb", "examples/assignments.rb", "examples/comparing.rb", "examples/enumerating.rb", "examples/game.rb", "examples/hello_world_patternitis.rb", "examples/indexing.rb", "examples/locking.rb", "examples/queue.rb", "examples/stack.rb", "install.rb", "lib/protocol.rb", "lib/protocol/core.rb", "lib/protocol/method_parser/ruby_parser.rb", "lib/protocol/version.rb", "protocol.gemspec", "tests/test_protocol.rb", "tests/test_protocol_method_parser.rb"]
  s.homepage = "http://flori.github.com/protocol"
  s.rdoc_options = ["--title", "Protocol - Method Protocols for Ruby Classes", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Method Protocols for Ruby Classes"
  s.test_files = ["tests/test_protocol.rb", "tests/test_protocol_method_parser.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<gem_hadar>, ["~> 0.1.8"])
      s.add_runtime_dependency(%q<ruby_parser>, ["~> 3.0"])
    else
      s.add_dependency(%q<gem_hadar>, ["~> 0.1.8"])
      s.add_dependency(%q<ruby_parser>, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<gem_hadar>, ["~> 0.1.8"])
    s.add_dependency(%q<ruby_parser>, ["~> 3.0"])
  end
end
