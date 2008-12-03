#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), 'helper')

require 'erb'
require 'w3c_validators'

class ValidateFixtures < Test::Unit::TestCase
  include W3CValidators

  def setup
    @v = MarkupValidator.new
    sleep 1 # delay per WC3 request
  end

  HTML_4_0_TEMPLATE = <<EOD
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
	<title><%= test_name %></title>
</head>
<body>
<%= content %>
</body>
</html>
EOD
  XHTML_1_0_TEMPLATE = <<EOD
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title><%= test_name %></title>
</head>
<body>
<%= content %>
</body>
</html>
EOD
  
  fixtures.each do |name, doc|
   if doc['html'] && (doc['valid_html'].nil? || doc['valid_html'])
     define_method("test_html_output_validity_of_#{name}") do
       assert_produces_valid_html(name, doc['html'])
     end
     define_method("test_xhtml_output_validity_of_#{name}") do
       assert_produces_valid_xhtml(name, doc['html'])
     end
   end
  end
  
  private
  def assert_produces_valid_html(test_name, content)
    body = ERB.new(HTML_4_0_TEMPLATE, nil,'-%').result(binding)    
    assert_validates(body)
  end

  def assert_produces_valid_xhtml(test_name, content)
    body = ERB.new(XHTML_1_0_TEMPLATE, nil,'-%').result(binding)    
    assert_validates(body)
  end
  
  def assert_validates(body)
    results = @v.validate_text(body)
    errors = results.errors
    warnings = results.warnings.reject {|w| w.message_id == "247" } # NET-enabling start-tag requires SHORTTAG YES.
    
    assert(errors.empty?, "Validator errors: \n" +
      errors.collect {|e| "'#{e.to_s}'"}.join("\n"))
    
    assert(warnings.empty?, "Validator warnings: \n" +
      warnings.collect {|w| "'#{w.to_s}'"}.join("\n"))
  end
  
end
