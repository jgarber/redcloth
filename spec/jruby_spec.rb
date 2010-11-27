require File.dirname(__FILE__) + '/spec_helper'

describe RedCloth do
  
  # FIXME: temporary test to isolate some JRuby problems
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
    html = <<-EOD
<div>html_block</div>
<h1>Heading</h1>
<p>standalone_html coming up.</p>
<div>
<p>Another p</p>
<div>test</div>
<p>Another p.</p>
    EOD
    RedCloth.new(input).to_html.should == html.strip
    
  end
end
