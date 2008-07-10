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
    assert_match /td/, RedCloth.new(%Q{| one | two |\nthree | four |}).to_html
  end
  
  def test_table_without_block_end_does_not_segfault
    assert_match /h3/, RedCloth.new("| a | b |\n| c | d |\nh3. foo").to_html
  end
  
  def test_table_with_empty_cells_does_not_segfault
    assert_match /td/, RedCloth.new(%Q{|one || |\nthree | four |}).to_html
  end
  
  def test_unfinished_html_block_does_not_segfault_with_filter_html
    assert_nothing_raised { RedCloth.new(%Q{<hr> Some text}, [:filter_html]).to_html }
  end
  
  def test_redcloth_version_in_output
    assert_equal "<p>#{RedCloth::VERSION}</p>", RedCloth.new("RedCloth::VERSION").to_html
  end
  
  def test_redcloth_version_only_on_line_by_itself
    input = "RedCloth::VERSION won't output the RedCloth::VERSION unless it's on a line all by itself.\n\nRedCloth::VERSION"
    html = "<p>RedCloth::<span class=\"caps\">VERSION</span> won&#8217;t output the RedCloth::<span class=\"caps\">VERSION</span> unless it&#8217;s on a line all by itself.</p>\n<p>#{RedCloth::VERSION}</p>"
    assert_equal html, RedCloth.new(input).to_html
  end

  def test_redcloth_version_with_label
    input = "RedCloth::VERSION: RedCloth::VERSION"
    html = "<p>RedCloth::VERSION: #{RedCloth::VERSION}</p>"
    assert_equal html, RedCloth.new(input).to_html
  end
  
  def test_redcloth_version_with_label_2
    input = "RedCloth version RedCloth::VERSION"
    html = "<p>RedCloth version #{RedCloth::VERSION}</p>"
    assert_equal html, RedCloth.new(input).to_html
  end
  
  def test_inline_redcloth_version
    input = "The current RedCloth version is [RedCloth::VERSION]"
    html = "<p>The current RedCloth version is #{RedCloth::VERSION}</p>"
    assert_equal html, RedCloth.new(input).to_html
  end

end
