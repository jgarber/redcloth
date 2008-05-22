#!/usr/bin/env ruby

require 'helper'

class TestRestrictions < Test::Unit::TestCase
  
  # security restrictions
  generate_formatter_tests('filtered_html') do |doc|
    assert_equal doc['filtered_html'],  RedCloth.new(doc['in'], [:filter_html]).to_html
  end
  generate_formatter_tests('sanitized_html') do |doc|
    assert_equal doc['sanitized_html'],  RedCloth.new(doc['in'], [:sanitize_html]).to_html
  end
  
  # pba filters (style, class, id)
  generate_formatter_tests('style_filtered_html') do |doc|
    assert_equal doc['style_filtered_html'],  RedCloth.new(doc['in'], [:filter_styles]).to_html
  end
  generate_formatter_tests('class_filtered_html') do |doc|
    assert_equal doc['class_filtered_html'],  RedCloth.new(doc['in'], [:filter_classes]).to_html
  end
  generate_formatter_tests('id_filtered_html') do |doc|
    assert_equal doc['id_filtered_html'],  RedCloth.new(doc['in'], [:filter_ids]).to_html
  end
  
  # hard breaks - has been deprecated and will be removed in a future version
  generate_formatter_tests('html_no_breaks') do |doc|
    red = RedCloth.new(doc['in'])
    red.hard_breaks = false
    assert_equal doc['html_no_breaks'],  red.to_html
  end

end
