require 'rubygems'
spec = Gem::Specification.new do |s|
  s.name = 'RedCloth'
  s.version = "2.0.6"
  s.platform = Gem::Platform::RUBY
  s.summary = "RedCloth is a module for using Textile in Ruby. Textile is a text format. A very simple text format. Another stab at making readable text that can be converted to HTML."
#  s.requirements << 'um?'
  s.files = ['tests/**/*', 'lib/**/*', 'docs/**/*', 'run-tests.rb'].collect do |dirglob|
                Dir.glob(dirglob)
            end.flatten.delete_if {|item| item.include?("CVS")}
  s.require_path = 'lib'
  s.autorequire = 'redcloth'
  s.author = "Why the Lucky Stiff"
  s.email = "why@ruby-lang.org"
# s.rubyforge_project = "redcloth"
  s.homepage = "http://www.whytheluckystiff.net/ruby/redcloth/"
end
if $0==__FILE__
p spec
  Gem::Builder.new(spec).build
end
