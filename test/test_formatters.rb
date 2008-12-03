#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), 'helper')

class TestFormatters < Test::Unit::TestCase
  
  generate_formatter_tests('html') do |doc|
    RedCloth.new(doc['in']).to_html
  end
  
  def test_html_orphan_parenthesis_in_link_can_be_followed_by_punctuation_and_words
    assert_nothing_raised { RedCloth.new(%Q{Test "(read this":http://test.host), ok}).to_html }
  end
  
  generate_formatter_tests('latex') do |doc|
    RedCloth.new(doc['in']).to_latex
  end

  def test_latex_orphan_parenthesis_in_link_can_be_followed_by_punctuation_and_words
    assert_nothing_raised { RedCloth.new(%Q{Test "(read this":http://test.host), ok}).to_latex }
  end
  

end
