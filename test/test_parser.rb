#!/usr/bin/env ruby

require 'test/unit'
require 'superredcloth'
require 'yaml'
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
      define_method("test_#{testgroup}_#{num}") do 
        assert_equal doc['out'], red(doc['in'])
      end
      num += 1
    end
  end
end
