#!/usr/bin/env ruby

require 'helper'

# Compare SuperRedCloth test fixtures to the output of Textile 2 (PHP)
class TestTextile2 < Test::Unit::TestCase
  DIR = File.dirname(__FILE__) unless defined? DIR
  
  # Adapted from TextMate HTML bundle
  $char_to_entity = { }
  File.open("#{DIR}/textile-2.0.0/entities.txt").read.scan(/^(\d+)\t(.+)$/) do |key, value|
    $char_to_entity[[key.to_i].pack('U')] = value
  end
  
  def convert_numeric_entities_to_named(str)
    # Adapted from TextMate HTML bundle
    str.gsub(/&#([0-9]+);/i) do |m|
      ch = [$1.to_i].pack("U")
      ent = $char_to_entity[ch]
      ent ? "&#{ent};" : sprintf("&#x%02X;", ch.unpack("U")[0])
    end
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
      define_method("test_textile2_compatibility_#{testgroup}_#{num}") do 
        assert_html_equal php(doc['in']), doc['out']
      end
      num += 1
    end
  end
end
