#!/usr/bin/env ruby

require 'helper'

# Test SuperRedCloth against the output of Textile 2 (PHP)
class TestParser < Test::Unit::TestCase
  DIR = File.dirname(__FILE__) unless defined? DIR
  
  def red(str)
    SuperRedCloth.new(str).to_html
  end
  
  def php(str)
    IO.popen("php #{DIR}/textile-2.0.0/stdin.php", "r+") do |t2|
      t2.puts str
      t2.close_write
      output = t2.gets(nil)
    end
  end
  
  Dir[File.join(DIR, "*.yml")].each do |testfile|
    testgroup = File.basename(testfile, '.yml')
    num = 0
    YAML::load_documents(File.open(testfile)) do |doc|
      define_method("test_textile2_compatibility_#{testgroup}_#{num}") do 
        assert_html_equal php(doc['in']), red(doc['in'])
      end
      num += 1
    end
  end
end
