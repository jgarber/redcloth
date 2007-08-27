require 'superredcloth_scan'

class << SuperRedCloth::HTML
  def pba opts
    atts = ''
    opts[:"text-align"] = opts.delete(:align)
    [:float, :"text-align"].each do |a|
      opts[:style] = "#{a}:#{opts[a]};#{opts[:style]}" if opts[a]
    end
    [:"padding-right", :"padding-left"].each do |a|
      opts[:style] = "#{a}:#{opts[a]}em;#{opts[:style]}" if opts[a]
    end
    [:style, :class, :lang, :id, :colspan, :rowspan, :title, :start, :valign, :align].each do |a|
      atts << " #{a}=\"#{ opts[a] }\"" if opts[a]
    end
    atts
  end
  [:h1, :h2, :h3, :h4, :h5, :h6, :p, :pre, :div].each do |m|
    define_method(m) do |opts|
      "<#{m}#{pba(opts)}>#{opts[:text]}</#{m}>"
    end
  end
  [:strong, :code, :em, :i, :b, :ins, :sup, :sub, :span, :cite, :acronym].each do |m|
    define_method(m) do |opts|
      opts[:block] = true
      "<#{m}#{pba(opts)}>#{opts[:text]}</#{m}>"
    end
  end
  def del(opts)
    opts[:block] = true
    " <del#{pba(opts)}>#{opts[:text]}</del> "
  end
  [:ol, :ul].each do |m|
    define_method("#{m}_open") do |opts|
      opts[:block] = true
      "<#{m}#{pba(opts)}>\n"
    end
    define_method("#{m}_close") do |opts|
      "#{li_close}</#{m}>"
    end
  end
  def li_open opts
    "#{li_close unless opts.delete(:first)}\t<li#{pba(opts)}>#{opts[:text]}"
  end
  def li_close(opts=nil)
    "</li>\n"
  end
  def ignore opts
    opts[:text]
  end
  alias_method :notextile, :ignore
  def para txt
    "<p>" + txt + "</p>"
  end
  def td opts
    tdtype = opts[:th] ? 'th' : 'td'
    "\t\t\t<#{tdtype}#{pba(opts)}>#{opts[:text]}</#{tdtype}>\n"
  end
  def tr_open opts
    "\t\t<tr#{pba(opts)}>\n"
  end
  def tr_close opts
    "\t\t</tr>\n"
  end
  def table_open opts
    "<table#{pba(opts)}>\n"
  end
  def table_close opts
    "\t</table>"
  end
  def bc opts
    opts[:block] = true
    "<pre#{pba(opts)}><code#{pba(opts)}>#{opts[:text]}</code></pre>"
  end
  def bq opts
    opts[:block] = true
    "<blockquote#{pba(opts)}><p#{pba(opts)}>#{opts[:text]}</p></blockquote>"
  end
  def link opts
    "<a href=\"#{opts[:href].gsub(/&/, '&#38;')}\"#{pba(opts)}>#{opts[:name]}</a>"
  end
  def image opts
    p_opts = {:float => opts.delete(:align)} if opts[:align]
    opts[:alt] = opts[:title]
    img = "<img src=\"#{urlesc opts[:src]}\"#{pba(opts)} alt=\"#{opts[:alt]}\" />"  
    img = "<a href=\"#{urlesc opts[:href]}\">#{img}</a>" if opts[:href]
    img = "<p#{pba(p_opts)}>#{img}</p>" if p_opts
    img
  end
  def footno opts
    opts[:id] ||= opts[:text]
    "<sup><a href=\"#fn#{opts[:id]}\">#{opts[:text]}</a></sup>"
  end
  def fn opts
    no = opts[:id]
    opts[:id] = "fn#{no}"
    "<p#{pba(opts)}><sup>#{no}</sup> #{opts[:text]}</p>"
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
    "&#8594;"
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
  def entity opts
    "&#{opts[:text]};"
  end
  def urlesc txt
    txt.gsub(/&/, '&amp;')
  end
end
