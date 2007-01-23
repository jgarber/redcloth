#!/usr/bin/env ruby

require 'test/unit'
require 'superredcloth'

class TestParser < Test::Unit::TestCase
  def red str
    SuperRedCloth.new(str).to_html
  end
  def test_para
    assert_equal "<p>test</p>", red("test")
  end
  def test_h1
    assert_equal "<h1>test</h1>", red("h1. test")
  end
  def test_image
    assert_equal %{<p>This is an <img src="http://example.com/i/image.jpg" alt="" />.</p>},
      red("This is an !http://example.com/i/image.jpg!.")
  end
  def test_glyphs
    assert_equal %{<p>abc<i>de</i>. And&#8230; this'll&#8212;or this&#8211;and &#8216;me&#8217;!</p>},
      red("abc__de__. And... this'll -- or this - and 'me'!")
  end
  def test_inline
    assert_equal "<p><code>test of <strong><em>this</em></strong></code></p>", red("@test of *_this_*@")
  end
  def test_blocks
    assert_equal %{<h1>Test</h1><p>abc <a href="/test2"><img src="/images/redhanded.gif" alt="" /></a> and <a href=\"http://google.com\">Google</a></p><p>OK</p>}, 
      red(%{h1. Test\n\nabc !/images/redhanded.gif!:/test2 and "Google(Test!)":http://google.com\n\nOK})
  end
end
