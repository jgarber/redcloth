require 'redcloth_scan'

$:.unshift(File.dirname(__FILE__))

require 'formatters/html'
require 'formatters/latex'

class RedCloth
  VERSION = '4.0.0'
  
  def initialize(input, opts=[])
    super(input)
  end
  
end
