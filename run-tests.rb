#!/usr/bin/env ruby
require 'redcloth'
require 'yaml'

Dir["tests/*.yml"].each do |testfile|
    YAML::load_documents( File.open( testfile ) ) do |doc|
        if doc['in'] and doc['out']
            html = RedCloth.new( doc['in'] ).to_html
            puts "---"
            if html == doc['out']
                puts "success: true"
            else
                puts "out: #{ html }"
                puts "expected: #{ doc['out'] }"
            end
        end
    end
end
