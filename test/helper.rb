require 'test/unit'
$:.unshift File.dirname(__FILE__) + "/../lib"
require 'redcloth'
require 'yaml'

def red(formatter, str)
  RedCloth.new(str).send("to_#{formatter}")
end

module Test
  module Unit
    module Assertions
      # Browsers ignore tabs and newlines (generally), so don't quibble
      def assert_html_equal(expected, actual, message=nil)
        assert_equal(expected.gsub(/[\n\t]+/, ''), actual.gsub(/[\n\t]+/, ''), message)
      end
    end
  end
end

# Colorize differences in assert_equal failure messages.
begin  
  require 'rubygems'
  require 'diff/lcs'
  require 'test/unit'
  
  DIFF_COLOR    = "\e[7m" unless defined?(DIFF_COLOR)
  DEFAULT_COLOR = "\e[0m" unless defined?(DEFAULT_COLOR)
  
  def highlight_differences(a, b)
    sdiff = Diff::LCS.sdiff(a, b, Diff::LCS::ContextDiffCallbacks)
    return highlight_string(sdiff, :old, a), highlight_string(sdiff, :new, b)
  end
  
  def highlight_string(sdiff, pos, s)
    s = s.dup
    offset = 0
    sdiff.each do |hunk|
      if hunk.first.send("#{pos}_element")
        s.insert(hunk.first.send("#{pos}_position") + offset, DIFF_COLOR)
        offset += DIFF_COLOR.length
      end
      if hunk.last.send("#{pos}_element")
        s.insert(hunk.last.send("#{pos}_position") + 1 + offset, DEFAULT_COLOR)
        offset += DEFAULT_COLOR.length
      end
    end
    s = DEFAULT_COLOR + s + DEFAULT_COLOR
  end
  
  module Test::Unit::Assertions
    # Show differences in expected and actual
    def assert_equal(expected, actual, message=nil)
      full_message = build_message(message, <<EOT, *highlight_differences(expected, actual))
expected: ?
 but was: ?
EOT
      assert_block(full_message) { expected == actual }
    end
  end
  
  
  module ShowColorCodes
     def self.included(base)
       base.class_eval do
         alias_method :result_without_color_codes, :result unless method_defined?(:result_without_color_codes)
         alias_method :result, :result_with_color_codes
       end
     end
     def result_with_color_codes(parameters)
       result_without_color_codes(parameters.collect {|p| p.gsub(/\\e\[(\d+)m/) {"\e[#{$1}m"} })
     end
   end
   Test::Unit::Assertions::AssertionMessage::Template.send(:include, ShowColorCodes)
rescue LoadError
end
