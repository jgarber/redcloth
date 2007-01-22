#!/usr/bin/env ruby

require 'test/unit'
require 'superredcloth'

class TestParser < Test::Unit::TestCase
  def red str
    SuperRedCloth.new(str).to_html
  end
  def test_set_attr
    assert_equal "<p>test</p>", red("test")
    assert_equal "<h1>test</h1>", red("h1. test")
    assert_equal "", red("This is an !http://example.com/i/image.jpg!.")
    assert_equal "<p>abc<i>de</i>.</p>", red("abc__de__. And... this'll -- or this - and 'me'!")
    assert_equal "<p><code>test</code></p>", red("@test of *_this_*@")
    assert_equal "<p>", red(%{h1. Test\n\nabc !/images/redhanded.gif!:/test2 and "Google(Test!)":http://google.com\n\nOK})
  end
end
