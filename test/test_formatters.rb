#!/usr/bin/env ruby

require 'helper'

class TestFormatters < Test::Unit::TestCase
  DIR = File.dirname(__FILE__)
  
  Dir[File.join(DIR, "*.yml")].each do |testfile|
    testgroup = File.basename(testfile, '.yml')
    num = 0
    YAML::load_documents(File.open(testfile)) do |doc|
      %w(html latex).each do |formatter|
        name = doc['name'] ? doc['name'].downcase.gsub(/[- ]/, '_') : num
        define_method("test_#{formatter}_#{testgroup}_#{name}") do
          assert_equal doc[formatter],  red(formatter, doc['in'])
        end if doc[formatter]
        num += 1
      end
    end
  end

end
