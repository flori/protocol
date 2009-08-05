begin
  require 'rake/gempackagetask'
rescue LoadError
end
require 'rake/clean'
require 'rbconfig'
include Config

PKG_NAME = 'protocol'
PKG_VERSION = File.read('VERSION').chomp
PKG_FILES = FileList['**/*'].exclude(/(CVS|\.svn|pkg|coverage)/)
CLEAN.include 'coverage', 'doc'

desc "Installing library"
task :install  do
  ruby 'install.rb'
end

desc "Creating documentation"
task :doc do
  ruby 'make_doc.rb'
end

desc "Testing library"
task :test  do
  ruby '-Ilib tests/test_protocol.rb'
end

desc "Testing library (coverage)"
task :coverage  do
  sh 'rcov -Ilib tests/test_protocol.rb'
end

if defined? Gem
  spec_src =<<GEM
# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
    s.name = '#{PKG_NAME}'
    s.version = '#{PKG_VERSION}'
    s.files = #{PKG_FILES.to_a.sort.inspect}
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
    s.homepage = "http://#{PKG_NAME}.rubyforge.org"
    s.rubyforge_project = "#{PKG_NAME}"
  end
GEM

  desc 'Create a gemspec file'
  task :gemspec do
    File.open("#{PKG_NAME}.gemspec", 'w') do |f|
      f.puts spec_src
    end
  end

  spec = eval(spec_src)
  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
    pkg.package_files += PKG_FILES
  end
end

desc m = "Writing version information for #{PKG_VERSION}"
task :version do
  puts m
  File.open(File.join('lib', 'protocol', 'version.rb'), 'w') do |v|
    v.puts <<EOT
module Protocol
  # Protocol version
  VERSION         = '#{PKG_VERSION}'
  VERSION_ARRAY   = VERSION.split(/\\./).map { |x| x.to_i } # :nodoc:
  VERSION_MAJOR   = VERSION_ARRAY[0] # :nodoc:
  VERSION_MINOR   = VERSION_ARRAY[1] # :nodoc:
  VERSION_BUILD   = VERSION_ARRAY[2] # :nodoc:
end
EOT
  end
end

desc "Default task"
task :default => [ :version, :gemspec, :test ]

desc "Prepare a release"
task :release => [  :clean, :version, :gemspec, :package ]
