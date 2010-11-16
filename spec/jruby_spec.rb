require File.dirname(__FILE__) + '/spec_helper'

describe RedCloth do
  
  it "should strip carriage returns" do
    input = <<-EOD
<div>html_block</div>

h1. Heading

standalone_html coming up.

<div>

Another p

<div>test</div>

Another p.

    EOD
    html = ""
    RedCloth.new(input).to_html.should == html
    
  end
end
