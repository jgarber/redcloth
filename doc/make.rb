require 'yaml'
require 'redcloth'

file_name = ARGV.shift
case file_name
when 'README'
    puts "<html>"
    puts "<head>"
    puts "<title>RedCloth [Textile Humane Web Text for Ruby]</title>"
    puts "</head>"
    puts "<body>"
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

    puts <<-HTML
    <html>
    <head>
    <title>Textile Quick Reference</title>
    <style type="text/css">
    BODY {
        margin: 10px 60px;
    }
    TABLE {
        font-family: georgia, serif;
        font-size: 12pt;
        padding: 15px;
        width: 250px;
    }
    TH {
        padding-top: 15px;
    }
    TD {
        border-top: solid 1px #eee;
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
    <table>
    <tr><th colspan=3><h1>Textile Quick Reference</h1></th></tr>
    HTML

    ct = 0
    content.each do |section|
        section.each do |header, parags|
            puts "<tr><th colspan=5>#{ header }</th></tr>" if ct.nonzero?
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
                   htmlesc!( :NoQuotes ).
                   gsub( /\n/, '<br />' ).
                   gsub( /;(\w)/, '; \1' ),
          RedCloth.new( val ).to_html ]
    end

    content = YAML::load( File.open( file_name ) )

    puts <<-HTML
    <html>
    <head>
    <title>Textile Reference</title>
    <style type="text/css">
    BODY {
        margin: 10px 60px;
    }
    TABLE {
        font-family: georgia, serif;
        font-size: 12pt;
        padding: 15px;
    }
    TH {
        border-bottom: solid 1px black;
        font-size: 24pt;
        font-weight: bold;
        padding-top: 30px;
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
    P.example1 {
        background-color: #A30;
        color: white;
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
        color: red
    }
    </style>
    </head>
    <body>
    <table>
    HTML

    ct = 0
    content.each do |section|
        section.each do |header, parags|
            if ct.zero?
                puts "<tr><th colspan=5><h1>#{ header }</h1></th></tr>"
            else
                puts "<tr><th colspan=5><small>#{ ct }.</small><br />#{ header }</th></tr>"
            end
            parags.each do |p|
                if p.is_a? Array
                    puts "<tr><td nowrap><p class='example1'>#{ p[0] }</p></td><td>&rarr;</td>" +
                             "<td><p class='example2'>#{ p[1] }</p></td><td>&rarr;</td>" +
                             "<td><p class='example3'>#{ p[2] }</p></td></tr>"
                else
                    puts "<tr><td class='explain' colspan=5>"
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
