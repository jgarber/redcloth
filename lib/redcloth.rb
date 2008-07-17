$:.unshift(File.dirname(__FILE__))

require 'redcloth_scan'
require 'redcloth/version'
require 'redcloth/textile_doc'
require 'redcloth/formatters/base'
require 'redcloth/formatters/html'
require 'redcloth/formatters/latex'

module RedCloth
  
  # A convenience method for creating a new TextileDoc. See
  # RedCloth::TextileDoc.
  def self.new( *args, &block )
    RedCloth::TextileDoc.new( *args, &block )
  end
  
  # Include extension modules (if any) in TextileDoc.
  def self.include(*args)
    RedCloth::TextileDoc.send(:include, *args)
  end
  
end

