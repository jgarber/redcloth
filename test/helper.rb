require 'test/unit'
$:.unshift File.dirname(__FILE__) + "/../lib"
require 'redcloth'
require 'yaml'

module Test
  module Unit
    
    class TestCase
      def self.generate_formatter_tests(formatter, &block)
        define_method("format_as_#{formatter}", &block)
        
        fixtures.each do |name, doc|
          if doc[formatter]
            define_method("test_#{formatter}_#{name}") do
              output = method("format_as_#{formatter}").call(doc)
              assert_equal doc[formatter], output
            end
          else
            define_method("test_#{formatter}_#{name}_raises_nothing") do
              assert_nothing_raised(Exception) { method("format_as_#{formatter}").call(doc) }
            end
          end
        end
      end
      
      def self.fixtures
        return @fixtures if @fixtures
        @fixtures = {}
        Dir[File.join(File.dirname(__FILE__), "*.yml")].each do |testfile|
          testgroup = File.basename(testfile, '.yml')
          num = 0
          YAML::load_documents(File.open(testfile)) do |doc|
            name = doc['name'] ? doc['name'].downcase.gsub(/[- ]/, '_') : num
            @fixtures["#{testgroup}_#{name}"] = doc
            num += 1
          end
        end
        @fixtures
      end
      
    end
    
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
