# -*- encoding: utf-8 -*-
# stub: protocol 2.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "protocol".freeze
  s.version = "2.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Florian Frank".freeze]
  s.date = "2024-07-14"
  s.description = "This library offers an implementation of protocols against which you can check\nthe conformity of your classes or instances of your classes. They are a bit\nlike Java Interfaces, but as mixin modules they can also contain already\nimplemented methods. Additionaly you can define preconditions/postconditions\nfor methods specified in a protocol.\n".freeze
  s.email = "flori@ping.de".freeze
  s.extra_rdoc_files = ["README.rdoc".freeze, "lib/protocol.rb".freeze, "lib/protocol/core.rb".freeze, "lib/protocol/descriptor.rb".freeze, "lib/protocol/errors.rb".freeze, "lib/protocol/message.rb".freeze, "lib/protocol/method_parser/ruby_parser.rb".freeze, "lib/protocol/post_condition.rb".freeze, "lib/protocol/protocol_module.rb".freeze, "lib/protocol/utilities.rb".freeze, "lib/protocol/version.rb".freeze, "lib/protocol/xt.rb".freeze]
  s.files = [".gitignore".freeze, ".travis.yml".freeze, ".utilsrc".freeze, "CHANGES".freeze, "COPYING".freeze, "Gemfile".freeze, "README.rdoc".freeze, "Rakefile".freeze, "VERSION".freeze, "benchmarks/data/.keep".freeze, "benchmarks/method_parser.rb".freeze, "examples/assignments.rb".freeze, "examples/comparing.rb".freeze, "examples/enumerating.rb".freeze, "examples/game.rb".freeze, "examples/hello_world_patternitis.rb".freeze, "examples/indexing.rb".freeze, "examples/queue.rb".freeze, "examples/stack.rb".freeze, "examples/synchronizing.rb".freeze, "install.rb".freeze, "lib/protocol.rb".freeze, "lib/protocol/core.rb".freeze, "lib/protocol/descriptor.rb".freeze, "lib/protocol/errors.rb".freeze, "lib/protocol/message.rb".freeze, "lib/protocol/method_parser/ruby_parser.rb".freeze, "lib/protocol/post_condition.rb".freeze, "lib/protocol/protocol_module.rb".freeze, "lib/protocol/utilities.rb".freeze, "lib/protocol/version.rb".freeze, "lib/protocol/xt.rb".freeze, "protocol.gemspec".freeze, "tests/protocol_core_test.rb".freeze, "tests/protocol_method_parser_test.rb".freeze, "tests/protocol_test.rb".freeze, "tests/test_helper.rb".freeze]
  s.homepage = "https://github.com/flori/protocol".freeze
  s.licenses = ["GPL-2".freeze]
  s.rdoc_options = ["--title".freeze, "Protocol - Method Protocols for Ruby Classes".freeze, "--main".freeze, "README.rdoc".freeze]
  s.rubygems_version = "3.5.11".freeze
  s.summary = "Method Protocols for Ruby Classes".freeze
  s.test_files = ["tests/protocol_core_test.rb".freeze, "tests/protocol_method_parser_test.rb".freeze, "tests/protocol_test.rb".freeze, "tests/test_helper.rb".freeze]

  s.specification_version = 4

  s.add_development_dependency(%q<gem_hadar>.freeze, ["~> 1.15.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<test-unit>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<ruby_parser>.freeze, ["~> 3.0".freeze])
end
