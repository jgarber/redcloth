require 'yaml'
require 'redcloth'

def a_name( phrase )
    phrase.downcase.
           gsub( /\W+/, '-' )
end

file_name = ARGV.shift
case file_name
when 'README'
    puts <<-HTML
    <html>
    <head>
    <title>RedCloth [Textile Humane Web Text for Ruby]</title>
    <style type="text/css">
    BODY {
        margin: 10px 60px;
        font-family: georgia, serif;
        font-size: 12pt;
    }
    TABLE {
        padding: 15px;
        width: 250px;
    }
    TH {
        text-align: left;
    }
    TD {
        border-top: solid 1px #eee;
    }
    H4 {
        border: solid 1px #caa;
        margin: 10px 15px 5px 10px;
        padding: 5px;
        color: white;
        background-color: #333;
        font-weight: bold;
        font-size: 12pt;
    }
    P {
        margin: 10px 15px 5px 15px;
    }
    P.example1 {
        background-color: #FEE;
        font-weight: bold;
        font-size: 9pt;
        padding: 5px;
    }
    P.example2 {
        border: solid 1px #DDD;
        background-color: #EEE;
        font-size: 9pt;
        padding: 5px;
    }
    .big {
        font-size: 15pt;
    }
    #big-red {
        font-size: 15pt;
        color: red;
    }
    </style>
    </head>
    <body>
    HTML
    puts RedCloth.new( File.open( file_name ).read ).to_html
    puts "</body>"
    puts "</html>"
when 'QUICK-REFERENCE'
    YAML::add_private_type( "example" ) do |type, val|
        esc = val.dup
        esc.htmlesc!( :NoQuotes )
        [ :example, esc.gsub( /\n/, '<br />' ),
          RedCloth.new( val ).to_html ]
    end

    content = YAML::load( File.open( 'REFERENCE' ) )

    sections = content.collect { |c| c.keys.first }
    sections.shift

    puts <<-HTML
    <html>
    <head>
    <title>Textile Quick Reference</title>
    <style type="text/css">
    BODY {
        margin: 5px;
    }
    TABLE {
        font-family: georgia, serif;
        font-size: 10pt;
        padding: 5px;
        width: 200px;
    }
    TH {
        padding-top: 10px;
    }
    TD {
        border-top: solid 1px #eee;
    }
    H1 {
        font-size: 18pt;
    }
    H4 {
        color: #999;
        background-color: #fee;
        border: solid 1px #caa;
        margin: 10px 15px 5px 10px;
        padding: 5px;
    }
    P {
        margin: 2px 5px 2px 5px;
    }
    P.example1 {
        background-color: #FEE;
        font-size: 8pt;
        padding: 5px;
    }
    P.example2 {
        border: solid 1px #DDD;
        background-color: #EEE;
        font-size: 8pt;
        padding: 5px;
    }
    .big {
        font-size: 12pt;
    }
    #big-red {
        font-size: 12pt;
        color: red;
    }
    </style>
    </head>
    <body>
    <table>
    <tr><th colspan=3><h1>Textile Quick Reference</h1></th></tr>
    <tr><th colspan=3>Sections: <nobr>#{ sections.collect { |s| "<a href='##{ a_name( s ) }'>#{ s }</a>" }.join( '</nobr> | <nobr>' ) }</nobr></th></tr>
    HTML

    ct = 0
    content.each do |section|
        section.each do |header, parags|
            puts "<tr><th colspan=5><a name='#{ a_name( header ) }'>#{ header }</a></th></tr>" if ct.nonzero?
            parags.each do |p|
                if p.is_a?( Array ) and p[0] == :example
                    puts "<tr><td nowrap><p class='example1'>#{ p[1] }</p></td><td>&rarr;</td>" +
                             "<td><p class='example3'>#{ p[2] }</p></td></tr>"
                end
            end
        end
        ct += 1
    end
    puts "</table>"
    puts "</body>"
    puts "</html>"

when 'REFERENCE'
    YAML::add_private_type( "example" ) do |type, val|
        esc = val.dup
        esc.htmlesc!( :NoQuotes )
        [ esc.gsub( /\n/, '<br />' ),
          RedCloth.new( val ).to_html.
                   gsub( /;(\w)/, '; \1' ).
                   htmlesc!( :NoQuotes ).
                   gsub( /\n/, '<br />' ),
          RedCloth.new( val ).to_html ]
    end

    content = YAML::load( File.open( file_name ) )

    puts <<-HTML
    <html>
    <head>
    <title>Textile Reference</title>
    <style type="text/css">
    BODY {
        margin: 10px 30px;
    }
    TABLE {
        font-family: georgia, serif;
        font-size: 11pt;
        padding: 15px;
    }
    TH {
        border-bottom: solid 1px black;
        font-size: 24pt;
        font-weight: bold;
        padding-top: 30px;
    }
    H1 {
        font-size: 42pt;
    }
    H4 {
        color: #999;
        background-color: #fee;
        border: solid 1px #caa;
        margin: 10px 15px 5px 10px;
        padding: 5px;
    }
    P {
        margin: 10px 15px 5px 15px;
    }
    TD.example1 P {
        background-color: #B30;
        color: white;
        font-weight: bold;
        font-size: 9pt;
        padding: 5px;
    }
    TD.example2 P {
        border: solid 1px #DDD;
        background-color: #EEE;
        font-size: 9pt;
        padding: 5px;
    }
    TD.example3 {
        border: solid 1px #EED;
        background-color: #FFE;
        padding: 5px;
    }
    .big {
        font-size: 15pt;
    }
    #big-red {
        font-size: 15pt;
        color: red
    }
    </style>
    <script language="JavaScript">
        function quickRedReference() {
            window.open( 
                "quick.html",
                "redRef",
                "height=600,width=550,channelmode=0,dependent=0," +
                "directories=0,fullscreen=0,location=0,menubar=0," +
                "resizable=0,scrollbars=1,status=1,toolbar=0"
            );
        }
    </script>
    </head>
    <body>
    <table>
    HTML

    ct = 0
    content.each do |section|
        section.each do |header, parags|
            if ct.zero?
                puts "<tr><th colspan=3><h1>#{ header }</h1></th></tr>"
            else
                puts "<tr><th colspan=3><small>#{ ct }.</small><br />#{ header }</th></tr>"
            end
            parags.each do |p|
                if p.is_a? Array
                    puts "<tr><td class='example1' valign='top' nowrap><p>#{ p[0] }</p></td><td>&rarr;</td>" +
                             "<td class='example2'><p>#{ p[1] }</p></td></tr><tr><td colspan='2'></td>" +
                             "<td class='example3'>#{ p[2] }</p></td></tr>"
                else
                    puts "<tr><td class='explain' colspan=3>"
                    puts RedCloth.new( p ).to_html
                    puts "</td></tr>"
                end
            end
            unless ct.zero?
                puts "<tr><td colspan=5 style='border-bottom: solid 1px #eee;'></tr>"
            end
        end
        ct += 1
    end
    puts "</table>"
    puts "</body>"
    puts "</html>"
end
