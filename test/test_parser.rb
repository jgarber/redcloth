#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), 'helper')

class TestParser < Test::Unit::TestCase

  def test_parser_accepts_options
    assert_nothing_raised(ArgumentError) do
      RedCloth.new("test", [:hard_breaks])
    end
  end
  
  def test_redcloth_has_version
    assert RedCloth.const_defined?("VERSION")
    assert RedCloth::VERSION.const_defined?("STRING")
  end
  
  def test_redcloth_version_to_s
    assert_equal RedCloth::VERSION::STRING, RedCloth::VERSION.to_s
    assert RedCloth::VERSION == RedCloth::VERSION::STRING
  end
  
  def test_badly_formatted_table_does_not_segfault
    assert_match(/td/, RedCloth.new(%Q{| one | two |\nthree | four |}).to_html)
  end
  
  def test_table_without_block_end_does_not_segfault
    assert_match(/h3/, RedCloth.new("| a | b |\n| c | d |\nh3. foo").to_html)
  end
  
  def test_table_with_empty_cells_does_not_segfault
    assert_match(/td/, RedCloth.new(%Q{|one || |\nthree | four |}).to_html)
  end
  
  def test_unfinished_html_block_does_not_segfault_with_filter_html
    assert_nothing_raised { RedCloth.new(%Q{<hr> Some text}, [:filter_html]).to_html }
  end
  
  def test_redcloth_version_in_output
    assert_equal "<p>#{RedCloth::VERSION::STRING}</p>", RedCloth.new("RedCloth::VERSION").to_html
  end
  
  def test_redcloth_version_only_on_line_by_itself
    input = "RedCloth::VERSION won't output the RedCloth::VERSION unless it's on a line all by itself.\n\nRedCloth::VERSION"
    html = "<p>RedCloth::<span class=\"caps\">VERSION</span> won&#8217;t output the RedCloth::<span class=\"caps\">VERSION</span> unless it&#8217;s on a line all by itself.</p>\n<p>#{RedCloth::VERSION::STRING}</p>"
    assert_equal html, RedCloth.new(input).to_html
  end

  def test_redcloth_version_with_label
    input = "RedCloth::VERSION: RedCloth::VERSION"
    html = "<p>RedCloth::VERSION: #{RedCloth::VERSION::STRING}</p>"
    assert_equal html, RedCloth.new(input).to_html
  end
  
  def test_redcloth_version_with_label_2
    input = "RedCloth version RedCloth::VERSION"
    html = "<p>RedCloth version #{RedCloth::VERSION::STRING}</p>"
    assert_equal html, RedCloth.new(input).to_html
  end
  
  def test_inline_redcloth_version
    input = "The current RedCloth version is [RedCloth::VERSION]"
    html = "<p>The current RedCloth version is #{RedCloth::VERSION::STRING}</p>"
    assert_equal html, RedCloth.new(input).to_html
  end
  
  def test_parser_strips_carriage_returns
    input = "This is a paragraph\r\n\r\nThis is a\r\nline break.\r\n\r\n<div>\r\ntest\r\n\r\n</div>"
    html = "<p>This is a paragraph</p>\n<p>This is a<br />\nline break.</p>\n<div>\n<p>test</p>\n</div>"
    assert_equal html, RedCloth.new(input).to_html
  end

end
