require 'redcloth_scan'

$:.unshift(File.dirname(__FILE__))

require 'formatters/html'
require 'formatters/latex'
require 'version'

class RedCloth
  include RedClothVersion
  
  #
  # Accessors for setting security restrictions.
  #
  # This is a nice thing if you're using RedCloth for
  # formatting in public places (e.g. Wikis) where you
  # don't want users to abuse HTML for bad things.
  #
  # If +:filter_html+ is set, HTML which wasn't
  # created by the Textile processor will be escaped.
  # Alternatively, if +:sanitize_html+ is set, 
  # HTML can pass through the Textile processor but
  # unauthorized tags and attributes will be removed.
  #
  # If +:filter_styles+ is set, it will also disable
  # the style markup specifier. ('{color: red}')
  #
  # If +:filter_classes+ is set, it will also disable
  # class attributes. ('!(classname)image!')
  #
  # If +:filter_ids+ is set, it will also disable
  # id attributes. ('!(classname#id)image!')
  #
  attr_accessor :filter_html, :sanitize_html, :filter_styles, :filter_classes, :filter_ids

  #
  # Accessor for toggling hard breaks.
  #
  # If +:hard_breaks+ is set, single newlines will
  # be converted to HTML break tags.  This is the
  # default behavior for traditional RedCloth.
  #
  attr_accessor :hard_breaks

  # Accessor for toggling lite mode.
  #
  # In lite mode, block-level rules are ignored.  This means
  # that tables, paragraphs, lists, and such aren't available.
  # Only the inline markup for bold, italics, entities and so on.
  #
  #   r = RedCloth.new( "And then? She *fell*!", [:lite_mode] )
  #   r.to_html
  #   #=> "And then? She <strong>fell</strong>!"
  #
  attr_accessor :lite_mode

  #
  # Accessor for toggling span caps.
  #
  # Textile places `span' tags around capitalized
  # words by default, but this wreaks havoc on Wikis.
  # If +:no_span_caps+ is set, this will be
  # suppressed.
  #
  attr_accessor :no_span_caps
  
  # Returns a new RedCloth object, based on _string_, observing 
  # any _restrictions_ specified.
  #
  #   r = RedCloth.new( "h1. A *bold* man" )
  #   r.to_html
  #     #=>"<h1>A <b>bold</b> man</h1>"
  #
  def initialize( string, restrictions = [] )
    restrictions.each { |r| method("#{r}=").call( true ) }
    @restrictions = restrictions
    super( string )
  end
  
end
