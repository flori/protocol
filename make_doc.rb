#!/usr/bin/env ruby
# vim: set et sw=2 ts=2:

$outdir = 'doc/'
puts "Creating documentation in '#$outdir'."
system "rdoc --main=doc-main.txt -o #$outdir doc-main.txt lib/protocol.rb"
