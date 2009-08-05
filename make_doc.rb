#!/usr/bin/env ruby

$outdir = 'doc/'
puts "Creating documentation in '#$outdir'."
system "rdoc --main=doc-main.txt -o #$outdir doc-main.txt #{Dir['lib/**/*.rb'] * ' '}"
