#!/usr/bin/env ruby

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

dest = File.join(CONFIG["sitelibdir"], 'protocol', 'method_parser')
mkdir_p dest
for file in Dir['lib/protocol/method_parser/*.rb']
  install(file, dest)
end
