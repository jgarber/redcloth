#!/usr/bin/env ruby

require 'helper'

class TestFormatters < Test::Unit::TestCase
  
  generate_formatter_tests('html') do |doc|
    assert_equal doc['html'],  RedCloth.new(doc['in']).to_html
  end
  
  generate_formatter_tests('latex') do |doc|
    assert_equal doc['latex'],  RedCloth.new(doc['in']).to_latex
  end

end
