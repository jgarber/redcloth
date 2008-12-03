#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), 'helper')

class TestExtensions < Test::Unit::TestCase
  
  require 'redcloth'
  
  # http://www.ralree.info/2006/9/13/extending-redcloth
  module RedClothSmileyExtension
    def refs_smiley(text)
      text.gsub!(/(\s)~(:P|:D|:O|:o|:S|:\||;\)|:'\(|:\)|:\()/) do |m|
        bef,ma = $~[1..2]
        filename = "/images/emoticons/"+(ma.unpack("c*").join('_'))+".png"
        "#{bef}<img src='#{filename}' title='#{ma}' class='smiley' />"
      end
    end
  end
  
  RedCloth.send(:include, RedClothSmileyExtension)

  def test_smiley
    input  = %Q{You're so silly! ~:P}
    
    str = RedCloth.new(input).to_html(:textile, :refs_smiley)

    html  = %Q{<p>You&#8217;re so silly! <img src='/images/emoticons/58_80.png' title=':P' class='smiley' /></p>}

    assert_equal(html, str)
  end
end
