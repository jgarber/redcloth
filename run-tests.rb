#!/usr/bin/env ruby
require 'lib/redcloth'
require 'yaml'
require 'rubygems'
require 'breakpoint' # for some reason, this allows the .'s to dynamically appear

puts "Running tests"
puts

Dir["test/*.yml"].each do |testfile|
    errors = []
    tests = 0
    print File.basename(testfile)+":\n\t"
    YAML::load_documents( File.open( testfile ) ) do |doc|
        if doc['in'] and doc['out']
            tests += 1
            red = RedCloth.new( doc['in'] )
            html = if testfile =~ /markdown/
                       red.to_html( :markdown )
                   elsif testfile =~ /docbook/
											 red.to_docbook
                   else
                       red.to_html
                   end

            html.gsub!( /\n+/, "\n" )
            doc['out'].gsub!( /\n+/, "\n" )
            if html == doc['out']
              print tests%10 == 0 ? tests : "."
            else
              print "x"
              errors << [doc['in'], html, doc['out']]              
            end
        end
    end
    if errors.each do |input, out, expected|
      puts
      puts "---"
			puts "in: "; p input
      puts "out: "; p out
      puts "expected: "; p expected
      puts "diff: "; puts (out.split-expected.split).join("\n")
      puts "---"
    end.empty?
      print " (#{tests} test#{'s' unless tests == 1})"
    end
    puts
end