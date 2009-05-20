$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])
require 'redcloth'
require 'yaml'

class FormatterExampleGroup < Spec::Example::ExampleGroup
  
  def self.examples_from_yaml(&block)
    formatter = description.downcase
    define_method("format_as_#{formatter}", &block)
    
    fixtures.each do |name, doc|
      if doc[formatter]
        example("should output #{formatter} for #{name}") do
          output = method("format_as_#{formatter}").call(doc)
          output.should == doc[formatter]
        end
      else
        example("should not raise errors when rendering #{formatter} for #{name}") do
          lambda { method("format_as_#{formatter}").call(doc) }.should_not raise_error
        end
      end
    end
  end
  
  def self.fixtures
    return @fixtures if @fixtures
    @fixtures = {}
    Dir[File.join(File.dirname(__FILE__), *%w[fixtures *.yml])].each do |testfile|
      testgroup = File.basename(testfile, '.yml')
      num = 0
      YAML::load_documents(File.open(testfile)) do |doc|
        name = doc['name'] || num
        @fixtures["#{testgroup} #{name}"] = doc
        num += 1
      end
    end
    @fixtures
  end
  
end

Spec::Example::ExampleGroupFactory.register(:formatter, FormatterExampleGroup)
