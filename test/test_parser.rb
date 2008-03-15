#!/usr/bin/env ruby

require 'helper'

class TestParser < Test::Unit::TestCase
  DIR = File.dirname(__FILE__)
  def red str
    SuperRedCloth.new(str).to_html
  end
  
  def red_latex str
    SuperRedCloth.new(str).to_latex
  end
  
  Dir[File.join(DIR, "*.yml")].each do |testfile|
    testgroup = File.basename(testfile, '.yml')
    num = 0
    YAML::load_documents(File.open(testfile)) do |doc|
      name = doc['name'] ? doc['name'].downcase.gsub(/[- ]/, '_') : num
      define_method("test_#{testgroup}_#{name}") do
        assert_equal doc['out'],  red(doc['in']) if doc['out']
        assert_equal doc['latex'], red_latex(doc['in']) if doc['latex']
      end
      num += 1
    end
  end
  
  def test_badly_formatted_table_does_not_segfault
    assert_match /td/, red(%Q{| one | two |\nthree | four |})
  end
  
  def test_table_without_block_end_does_not_segfault
    assert_match /h3/, red("| a | b |\n| c | d |\nh3. foo")
  end
  
  def test_table_with_empty_cells_does_not_segfault
    assert_match /td/, red(%Q{|one || |\nthree | four |})
  end
end
