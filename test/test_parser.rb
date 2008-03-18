#!/usr/bin/env ruby

require 'helper'

class TestParser < Test::Unit::TestCase

  def test_parser_accepts_options
    assert_nothing_raised(ArgumentError) do
      RedCloth.new("test", [:hard_breaks])
    end
  end
  
  def test_badly_formatted_table_does_not_segfault
    assert_match /td/, red("html", %Q{| one | two |\nthree | four |})
  end
  
  def test_table_without_block_end_does_not_segfault
    assert_match /h3/, red("html", "| a | b |\n| c | d |\nh3. foo")
  end
  
  def test_table_with_empty_cells_does_not_segfault
    assert_match /td/, red("html", %Q{|one || |\nthree | four |})
  end

end
