#!/usr/bin/env ruby

require 'helper'

class TestFormatters < Test::Unit::TestCase
  
  generate_formatter_tests('html') do |doc|
    RedCloth.new(doc['in']).to_html
  end
  
  generate_formatter_tests('latex') do |doc|
    RedCloth.new(doc['in']).to_latex
  end

end
