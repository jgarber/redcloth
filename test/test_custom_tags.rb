#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), 'helper')

class TestCustomTags < Test::Unit::TestCase

  module FigureTag
    def fig( opts )
      label, img = opts[:text].split('|').map! {|str| str.strip}

      html  = %Q{<div class="img" id="figure-#{label.tr('.', '-')}">\n}
      html << %Q{  <a class="fig" href="/images/#{img}">\n}
      html << %Q{    <img src="/images/thumbs/#{img}" alt="Figure #{label}" />\n}
      html << %Q{  </a>\n}
      html << %Q{  <p>Figure #{label}</p>\n}
      html << %Q{<div>\n}
    end
  end

  def test_fig_tag
    input  = %Q{The first line of text.\n\n}
    input << %Q{fig. 1.1 | img.jpg\n\n}
    input << %Q{The last line of text.\n}
    r = RedCloth.new input
    r.extend FigureTag
    str = r.to_html

    html  = %Q{<p>The first line of text.</p>\n}
    html << %Q{<div class="img" id="figure-1-1">\n}
    html << %Q{  <a class="fig" href="/images/img.jpg">\n}
    html << %Q{    <img src="/images/thumbs/img.jpg" alt="Figure 1.1" />\n}
    html << %Q{  </a>\n}
    html << %Q{  <p>Figure 1.1</p>\n}
    html << %Q{<div>\n}
    html << %Q{<p>The last line of text.</p>}

    assert_equal(html, str)
  end

  def test_fallback
    r = RedCloth.new %Q/fig()>[no]{color:red}. 1.1 | img.jpg/
    str = r.to_html

    assert_equal "<p>fig()>[no]{color:red}. 1.1 | img.jpg</p>", str
  end
  
  # We don't want to call just any String method!
  def test_does_not_call_standard_methods
    r = RedCloth.new "next. "
    r.extend FigureTag
    str = r.to_html

    html  = "<p>next. </p>"

    assert_equal(html, str)
  end
  
end
