#!/usr/bin/env ruby
# vim: set et sw=2 ts=2:

require 'rbconfig'
require 'fileutils'
include FileUtils::Verbose

include Config

file = 'lib/protocol.rb'
dest = CONFIG["sitelibdir"]
install(file, dest)

dest = File.join(CONFIG["sitelibdir"], 'protocol')
mkdir_p dest
for file in Dir['lib/protocol/*.rb']
  install(file, dest)
end
