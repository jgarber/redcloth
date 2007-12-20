#!/usr/bin/env ruby

require 'helper'

# Compare SuperRedCloth test fixtures to the output of Textile 2 (PHP)
class TestTextile2 < Test::Unit::TestCase
  DIR = File.dirname(__FILE__) unless defined? DIR
  
  def convert_numeric_entities_to_named(str)
    # Only these should be named for XML compliance.
    # See: http://rubyforge.org/pipermail/redcloth-upwards/2007-August/000161.html
    str.gsub!(/&#38;/, "&amp;")
    str.gsub!(/&#60;/, "&lt;")
    str.gsub!(/&#62;/, "&gt;")
    str.gsub!(/&#8220;/, "&quot;")
    str
  end
  
  def red(str)
    SuperRedCloth.new(str).to_html
  end
  
  def php(str)
    output = ''
    IO.popen("php #{DIR}/textile-2.0.0/stdin.php", "r+") do |t2|
      t2.puts str
      t2.close_write
      output = t2.gets(nil)
    end
    convert_numeric_entities_to_named(output) # Named vs. numeric entities is an intentional difference
  end
  
  Dir[File.join(DIR, "*.yml")].each do |testfile|
    testgroup = File.basename(testfile, '.yml')
    num = 0
    YAML::load_documents(File.open(testfile)) do |doc|
      name = doc['name'] ? doc['name'].downcase.gsub(/[- ]/, '_') : "#{testgroup}_#{num}"
      define_method("test_textile2_compatibility_#{testgroup}_#{name}") do 
        assert_html_equal php(doc['in']), doc['out']
      end
      num += 1
    end
  end
end
