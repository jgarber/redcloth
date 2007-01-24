require 'superredcloth_scan'

class << SuperRedCloth
  def pba opts
    atts = ''
    [:style, :class, :lang, :id, :colspan, :rowspan, :title].each do |a|
      atts << " #{a}=\"#{ opts[a] }\"" if opts[a]
    end
    atts
  end
  [:h1, :h2, :h3, :h4, :h5, :h6, :p].each do |m|
    define_method(m) do |opts|
      "<#{m}#{pba(opts)}>#{opts[:text]}</#{m}>"
    end
  end
  [:strong, :code, :em, :i, :b, :del, :ins, :sup, :sub, :span, :cite, :acronym].each do |m|
    define_method(m) do |opts|
      "<#{m}#{pba(opts)}>#{opts[:text]}</#{m}>"
    end
  end
  def ignore opts
    opts[:text]
  end
  def para txt
    "<p>" + txt + "</p>"
  end
  def bq opts
    "<blockquote><p>" + opts[:text] + "</p></blockquote>"
  end
  def link opts
    "<a href=\"#{opts[:href].gsub(/&/, '&#38;')}\"#{pba(opts)}>#{opts[:name]}</a>"
  end
  def image opts
    opts[:alt] = opts[:title]
    img = "<img src=\"#{opts[:src]}\"#{pba(opts)} alt=\"#{opts[:alt]}\" />"  
    img = "<a href=\"#{urlesc opts[:href]}\">#{img}</a>" if opts[:href]
    img
  end
  def footno opts
    opts[:id] ||= opts[:text]
    "<sup><a href=\"#fn#{opts[:id]}\">#{opts[:text]}</a></sup>"
  end
  def fn opts
    "<p id=\"fn#{opts[:id]}\"><sup>#{opts[:id]}</sup> #{opts[:text]}</p>"
  end
  def snip opts
    "<pre#{pba(opts)}><code>#{opts[:text]}</code></pre>"
  end
  def quote1 opts
    "&#8216;#{opts[:text]}&#8217;"
  end
  def quote2 opts
    "&#8220;#{opts[:text]}&#8221;"
  end
  def ellipsis opts
    "#{opts[:text]}&#8230;"
  end
  def emdash opts
    "&#8212;"
  end
  def endash opts
    "&#8211;"
  end
  def arrow opts
    "&rarr;"
  end
  def dim opts
    "#{opts[:x]}&#215;#{opts[:y]}"
  end
  def trademark opts
    "&#8482;"
  end
  def registered opts
    "&#174;"
  end
  def copyright opts
    "&#169;"
  end
  def urlesc txt
    txt.gsub(/&/, '&#38;')
  end
end
