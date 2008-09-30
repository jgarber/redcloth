#!/usr/bin/env ruby

require 'helper'

class TestErb < Test::Unit::TestCase

  def test_redcloth_erb
    template = %{<%=redcloth_escape "This new ERB tag makes is so _easy_ to use *RedCloth*" %>}
    expected = %{This is a test. <p><span class="caps">ERB in RedCloth</p>}
    assert_equal expected, ERB.new(template).result
  end

end
