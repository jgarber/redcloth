#!/usr/bin/env ruby

require 'helper'

class TestParser < Test::Unit::TestCase
  DIR = File.dirname(__FILE__)
  def red str
    SuperRedCloth.new(str).to_html
  end
  Dir[File.join(DIR, "*.yml")].each do |testfile|
    testgroup = File.basename(testfile, '.yml')
    num = 0
    YAML::load_documents(File.open(testfile)) do |doc|
      name = doc['name'] ? doc['name'].downcase.gsub(/[- ]/, '_') : num
      define_method("test_#{testgroup}_#{name}") do 
        assert_html_equal doc['out'], red(doc['in'])
      end
      num += 1
    end
  end
end
