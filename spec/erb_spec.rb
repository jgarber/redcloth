require File.dirname(__FILE__) + '/spec_helper'
require 'redcloth/erb_extension'

describe "ERB helper" do
  it "should add a textile tag to ERB" do
    erb_class = Class.new do
      include ERB::Util
      
      def main
        input = %{<%= textilize "This new ERB tag makes is so _easy_ to use *RedCloth*" %>}
        ERB.new(input).result(binding)
      end
    end
    
    expected = %{<p>This new <span class="caps">ERB</span> tag makes is so <em>easy</em> to use <strong>RedCloth</strong></p>}
    
    erb_class.new.main.should == expected
  end
end
