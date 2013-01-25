# vim: set filetype=ruby et sw=2 ts=2:

require 'gem_hadar'

GemHadar do
    name                 'protocol'
    author               'Florian Frank'
    email                'flori@ping.de'
    homepage             "http://flori.github.com/#{name}"
    summary              'Method Protocols for Ruby Classes'
    description <<EOT
This library offers an implementation of protocols against which you can check
the conformity of your classes or instances of your classes. They are a bit
like Java Interfaces, but as mixin modules they can also contain already
implemented methods. Additionaly you can define preconditions/postconditions
for methods specified in a protocol.
EOT
  test_dir               'tests'
  ignore                 '.*.sw[pon]', 'pkg', 'Gemfile.lock', 'coverage', '.rvmrc', '.AppleDouble'
  readme                 'README.rdoc'
  dependency             'ruby_parser', '~> 3.0'
  development_dependency 'simplecov'

  install_library do
    file = 'lib/protocol.rb'
    dest = CONFIG["sitelibdir"]
    install(file, dest)

    dest = File.join(CONFIG["sitelibdir"], 'protocol')
    mkdir_p dest
    for file in Dir['lib/protocol/*.rb']
      install(file, dest)
    end

    dest = File.join(CONFIG["sitelibdir"], 'protocol', 'method_parser')
    mkdir_p dest
    for file in Dir['lib/protocol/method_parser/*.rb']
      install(file, dest)
    end
  end
end
