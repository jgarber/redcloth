require 'yaml'
require 'redcloth'

file_name = ARGV.shift
case file_name
when 'REFERENCE'
    YAML::add_private_type( "example" ) do |type, val|
        "| <notextile>#{ val }</notextile> | -> | #{ RedCloth.new( val ).to_html.htmlesc!( :NoQuotes ) } | -> | #{ RedCloth.new( val ).to_html } |"
    end

    content = YAML::load( File.open( file_name ) )
    content.each do |section|
        section.each do |header, parags|
            puts "<h1>#{ header }</h1>"
            parags.each do |p|
                puts RedCloth.new( p ).to_html
            end
        end
    end
end
