#
# = RedCloth - Textile for Ruby
#
# (c) 2003 why the lucky stiff (and his puppet organizations.)
#
# (see http://www.textism.com/tools/textile/ for Textile)
#
# Based on (and also inspired by) both:
#
# PyTextile: http://diveintomark.org/projects/textile/textile.py.txt
# Textism for PHP: http://www.textism.com/tools/textile/
# 
#
# == What is Textile?
#
# Textile is a simple formatting style for text
# documents, loosely based on some HTML conventions.
#
# === Sample Textile Text
#
#  h2. This is a title
#
#  h3. This is a subhead
#
#  This is a bit of paragraph.
#
#  bq. This is a blockquote.
#
# === Writing Textile
#
# A Textile document consists of paragraphs.  Paragraphs
# can be specially formatted by adding a small instruction
# to the beginning of the paragraph.
#
#  h[n].   Header of size [n].
#  bq.     Blockquote.
#  #       Numeric list.
#  *       Bulleted list.
#
# === Quick Phrase Modifiers
#
# Quick phrase modifiers are also included, to allow formatting
# of small portions of text within a paragraph.
#
#  _emphasis_
#  __italicized__
#  *strong*
#  **bold**
#  ??citation??
#  -deleted text-
#  +inserted text+
#  ^superscript^
#  ~subscript~
#  @code@
#  %(classname)span%
#
# === Links
#
# To make a hypertext link, put the link text in "quotation 
# marks" followed immediately by a colon and the URL of the link.
# 
# Optional: text in (parentheses) following the link text, 
# but before the closing quotation mark, will become a Title 
# attribute for the link, visible as a tool tip when a cursor is above it.
# 
# Example:
#
#  "This is a link (This is a title) ":http://www.textism.com
# 
# Will become:
# 
#  <a href="http://www.textism.com" title="This is a title">This is a link</a>
#
# === Images
#
# To insert an image, put the URL for the image inside exclamation marks.
#
# Optional: text that immediately follows the URL in (parentheses) will 
# be used as the Alt text for the image. Images on the web should always 
# have descriptive Alt text for the benefit of readers using non-graphical 
# browsers.
#
# Optional: place a colon followed by a URL immediately after the 
# closing ! to make the image into a link.
# 
# Example:
#
#  !http://www.textism.com/common/textist.gif(Textist)!
#
# Will become:
#
# <img src="http://www.textism.com/common/textist.gif" alt="Textist" />
#
# With a link:
#
#  !/common/textist.gif(Textist)!:http://textism.com
#
# Will become:
#
#  <a href="http://textism.com"><img src="/common/textist.gif" alt="Textist" /></a>
#
# === Defining Acronyms
#
# HTML allows authors to define acronyms via the tag. The definition appears as a 
# tool tip when a cursor hovers over the acronym. A crucial aid to clear writing, 
# this should be used at least once for each acronym in documents where they appear.
#
# To quickly define an acronym in Textile, place the full text in (parentheses) 
# immediately following the acronym.
# 
# Example:
#
#  ACLU(American Civil Liberties Union)
#
# Will become:
#
#  <acronym title="American Civil Liberties Union">ACLU</acronym>
#
# === Adding Tables
#
# In Textile, simple tables can be added by seperating each column by
# a pipe.
#
#     |a|simple|table|row|
#     |And|Another|table|row|
#
# === Using RedCloth
# 
# RedCloth is simply an extension of the String class, which can handle
# Textile formatting.  Use it like a String and output HTML with its
# RedCloth#to_html method.
#
#  doc = RedCloth.new "
#
#  h2. Test document
#
#  Just a simple test."
#
#  puts doc.to_html

class String
    #
    # Flexible HTML escaping
    #
    def htmlesc!( mode )
        gsub!( '&', '&amp;' )
        gsub!( '"', '&quot;' ) if mode != :NoQuotes
        gsub!( "'", '&#039;' ) if mode == :Quotes
        gsub!('<', '&lt;')
        gsub!('>', '&gt;')
    end
end

class RedCloth < String

    #
    # Mapping of 8-bit ASCII codes to HTML numerical entity equivalents.
    # (from PyTextile)
    #
    TEXTILE_TAGS = 

        [[128, 8364], [129, 0], [130, 8218], [131, 402], [132, 8222], [133, 8230], 
         [134, 8224], [135, 8225], [136, 710], [137, 8240], [138, 352], [139, 8249], 
         [140, 338], [141, 0], [142, 0], [143, 0], [144, 0], [145, 8216], [146, 8217], 
         [147, 8220], [148, 8221], [149, 8226], [150, 8211], [151, 8212], [152, 732], 
         [153, 8482], [154, 353], [155, 8250], [156, 339], [157, 0], [158, 0], [159, 376]].

        collect! do |a, b|
            [a.chr, ( b.zero? and "" or "&#{ b };" )]
        end

    #
    # Regular expressions to convert to HTML.
    #
    A_HLGN = /(?:\<(?!>)|\<\>|\=|[()]+)/
    A_VLGN = /[\-^~]/
    C_CLAS = /(?:\([^)]+\))/
    C_LNGE = /(?:\[[^\]]+\])/
    C_STYL = /(?:\{[^}]+\})/
    S_CSPN = /(?:\\\\\d+)/
    S_RSPN = /(?:\/\d+)/
    A = /(?:#{A_HLGN}?#{A_VLGN}?|#{A_VLGN}?#{A_HLGN}?)/
    S = /(?:#{S_CSPN}?#{S_RSPN}|#{S_RSPN}?#{S_CSPN}?)/
    C = /(?:#{C_CLAS}?#{C_STYL}?#{C_LNGE}?|#{C_STYL}?#{C_LNGE}?#{C_CLAS}?|#{C_LNGE}?#{C_STYL}?#{C_CLAS}?)/
    PUNCT = /[\!"#\$%&\'()\*\+,\-\.\/:;<=>\?@\[\\\]\^_`{\|}\~]/


    HYPERLINK = '(\S+?)([^\w\s\/;=\?]*?)(\s|$)'
    TEXTILE_TAGS.push(

        # incoming ampersands into dummy char
        [ /&(?![#a-zA-Z0-9]+;)/, 'x%x%' ],

        # unescape incoming elements
        [ "&gt;", ">" ],
        [ "&lt;", "<" ],
        [ "&amp;", "&" ],

        # normalize linefeeds
        [ /\r\n/, "\n" ],
        [ /\n{3,}/, "\n\n" ],
        [ /\n +\n/, "\n\n" ],
        [ /"$/, '" ' ],

        # get references
        [ /(^|\s)\[(.+?)\]((?:http:\/\/|\/)\S+)(?=\s|$)/, proc { @urlRefs ||= {}; @urlRefs[$2] = $3; $1 } ],

        ### QUICK TAGS ###

        # double equals -> <notextile>
        [ /(^|\s)==(.*?)==([^\w]{0,2})/, '\1<notextile>\2</notextile>\3' ],

        # image -> <img>
        [ /!([^\s\(=!]+?)\s?(\(([^\)]+?)\))?!/, '<img src="\1" alt="\3" />' ],

        # image with hyperlink -> <a><img>
        [ /(<img.+ \/>):#{ HYPERLINK }/, '<a href="\2">\1</a>\3\4' ],

        # hyperlink -> <a>
        [ /"([^"\(]+)\s?(\(([^\)]+)\))?":#{ HYPERLINK }/, '<a href="\4" title="\3">\1</a>\5\6' ]

    )

    #
    # Quick phrase modifiers. 
    #
    PHRASE_MODS = [
        [ '**', 'b' ],
        [ '*', 'strong' ],
        [ '??', 'cite' ],
        [ '-', 'del' ],
        [ '+', 'ins' ],
        [ '~', 'sub' ],
        [ '@', 'code' ],
        [ '__', 'i' ],
        [ '_', 'em' ],
        [ '^', 'sup' ]
    ]

    TEXTILE_TAGS.concat(
        PHRASE_MODS.collect do |texttag, htmltag|
            [ /(^|\s)#{ Regexp::quote( texttag ) }(.*?)#{ Regexp::quote( texttag ) }([^\w\s]{0,2})/, 
              '\1<' + htmltag + '>\2</' + htmltag + '>\3' ]
        end
    )

    # quotes at end of line
    TEXTILE_TAGS.push(
        [ /"$/, '" ' ]
    )
    
    #
    # Encodings and special characters.
    #
    GLYPHS = [
        [ /([^\s\[{(>])?\'([dmst]\b|ll\b|ve\b|\s|:|$)/, '\1&#8217;\2' ], # single closing
        [ /\'/, '&#8216;' ], # single opening
        [ /([^\s\[{(])?"(\s|:|$)/, '\1&#8221;\2' ], # double closing
        [ /"/, '&#8220;' ], # double opening
        [ /\b( )?\.{3}/, '\1&#8230;' ], # ellipsis
        [ /\b([A-Z][A-Z0-9]{2,})\b(\(([^\)]+)\))/, '<acronym title="\3">\1</acronym>' ], # 3+ uppercase acronym
        [ /(^|[^"][>\s])([A-Z][A-Z0-9 ]{2,})([^<a-z0-9]|$)/, '\1<span class="caps">\2</span>\3' ], # 3+ uppercase caps
        [ /\s?--\s?/, '&#8212;' ], # em dash
        [ /\s-\s/, ' &#8211; ' ], # en dash
        [ /(\d+) ?x ?(\d+)/, '\1&#215;\2' ], # dimension sign
        [ /\b ?(\((tm|TM)\))/, '&#8482;' ], # trademark
        [ /\b ?(\([rR]\))/, '&#174;' ], # registered
        [ /\b ?(\([cC]\))/, '&#169;' ] # registered
    ]

    TEXTILE_PREP_BLOCK = [

        # deal with forced breaks; this is going to be a problem between
        #  <pre> tags, but we'll clean them later
        [ /(\\S)(_*?)([^\\w\\s]*?) *?\n([^#*\\s])/, '\1\2\3<br />\4' ],

        # might be a problem with lists
        [ /l><br \/>/, "l>\n" ]

    ]

    BLOCKS = [
        [ /^\s?\*\s(.*)/, "<liu>\\1</liu>" ], # bulleted list *
        [ /^\s?#\s(.*)/, "<lio>\\1</lio>" ], # numeric list #
        [ /^bq\. (.*)/, "<blockquote>\\1</blockquote>" ], # blockquote bq.
        [ /^h(\d)\(([\w]+)\)\.\s(.*)/, "<h\\1 class=\"\\2\">\\3</h\\1>" ], # header hn(class).  w/ css class
        [ /^h(\d)\. (.*)/, "<h\\1>\\2</h\\1>" ], # plain header hn.
        [ /^p\(([\w]+)\)\.\s(.*)/, "<p class=\"\\1\">\\2</p>" ], # para p(class).  w/ css class
        [ /^p\. (.*)/, "<p>\\1</p>" ], # plain paragraph
        [ /^([^\t ]+.*)/, "<p>\\1</p>" ] # remaining plain paragraph
    ]

    TEXTILE_CLEAN = [

        # clean out <notextile>
        [ /<\/?notextile>/, "" ],
                
        # clean up liu and lio
        [ /<(\/?)li(u|o)>/, '<\1li>' ],
        
        # clean up empty titles
        [ / title=""/, '' ],
        
        # turn the temp char back to an ampersand entity
        [ /x%x%/, "&#38;" ],
        
        # Newline linebreaks, just for markup tidiness
        [ /<br \/>/, "<br />\n" ]

    ]

    #
    # Generate HTML.
    #
    def to_html

        # make our working copy
        text = self.dup

        # apply first set of replacements
        TEXTILE_TAGS.each do |re, resub|
            if resub.respond_to? :call
                text.gsub! re, &resub
            else
                text.gsub! re, resub
            end
        end

        # flag for inside of <code> and <pre> tags
        codepre = false 

        # apply GLYPHs based on if there is HTML content
        if /<.*>/.match text
            text = text.split( /(<.*?>)/ ).collect do |line|
                case line.downcase
                when /<(code|pre|kbd|notextile)>/
                    codepre = true
                when /<\/(code|pre|kbd|notextile)>/
                    codepre = false
                when /<.*?>/
                    if codepre
                        line.htmlesc! :NoQuotes
                        line.gsub! '&lt;pre&gt;', '<pre>'
                        line.gsub! '&lt;code&gt;', '<code>'
                    end
                else
                    unless codepre
                        GLYPHS.each do |re, resub|
                            line.gsub! re, resub
                        end
                    end
                end
                line
            end.join
        else
            GLYPHS.each do |re, resub|
                text.gsub! re, resub
            end
        end

        # prepare for block replacements
        TEXTILE_PREP_BLOCK.each do |re, resub|
            text.gsub! re, resub
        end

        list = ''
        pre = false

        # apply block replacements
        text = text.split( "\n" ).collect do |line|

            # make sure line isn't blank
            unless line.empty?

                # matches are off if we're between <pre> tags
                pre = true if line.downcase.include? '<pre>'

                # deal with block replacements first, then see if we're in a list
                BLOCKS.each { |re, resub| break if line.gsub! re, resub } unless pre

                # kill any br tags that slipped in earlier
                line.gsub!( '<br />', "\n" ) if pre

                # matches are back on after </pre>
                pre = false if line.downcase.include? '</pre>'

            end

            # at the beginning of a list, $line switches to a value
            if list.empty? and line.include? "<li"
                list = line[3,1] # "u" or "o", presumably
                line.gsub!( /^(<li)(o|u)/, "\n<\\2l>\n\\1\\2" )
            elsif not list.empty? and not line.include? "<li#{ list }"
                line.gsub!( /^(.*)$/, "</#{ list }l>\n\\1" )
                list = ''
            end

            line

        end.join( "\n" )

        # apply cleaning replacements
        TEXTILE_CLEAN.each do |re, resub|
            text.gsub! re, resub
        end

        text

    end

end

