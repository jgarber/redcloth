#!/usr/bin/env ruby

require 'helper'

class TestParser < Test::Unit::TestCase

  def test_parser_accepts_options
    assert_nothing_raised(ArgumentError) do
      RedCloth.new("test", [:hard_breaks])
    end
  end
  
  # If RedCloth::VERSION isn't defined, it will pick up VERSION from Ruby (e.g. 1.8.6)
  # but won't necessarily raise an exception.
  def test_redcloth_has_version
    assert RedCloth.included_modules.include?(RedClothVersion)
    assert RedClothVersion.const_defined?("VERSION")
    assert_equal RedClothVersion::VERSION, RedCloth::VERSION
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
  
  def test_redcloth_version_in_output
    assert_equal "<p>#{RedCloth::VERSION}</p>", red("html", "RedCloth::VERSION")
  end
  
  def test_redcloth_version_only_on_line_by_itself
    input = "RedCloth::VERSION won't output the RedCloth::VERSION unless it's on a line all by itself.\n\nRedCloth::VERSION"
    html = "<p>RedCloth::<span class=\"caps\">VERSION</span> won&#8217;t output the RedCloth::<span class=\"caps\">VERSION</span> unless it&#8217;s on a line all by itself.</p>\n<p>#{RedCloth::VERSION}</p>"
    assert_equal html, red("html", input)
  end

end
