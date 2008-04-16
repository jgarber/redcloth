class << RedCloth::HTML
  def options
    {:html_escape_entities => true}
  end
  
  def after_transform(text)
    text.chomp!
  end
  
  def pba(opts)
    atts = ''
    opts[:"text-align"] = opts.delete(:align)
    opts[:style] += ';' if opts[:style] && (opts[:style][-1..-1] != ';')
    [:float, :"text-align", :"vertical-align"].each do |a|
      opts[:style] = "#{a}:#{opts[a]};#{opts[:style]}" if opts[a]
    end
    [:"padding-right", :"padding-left"].each do |a|
      opts[:style] = "#{a}:#{opts[a]}em;#{opts[:style]}" if opts[a]
    end
    [:style, :class, :lang, :id, :colspan, :rowspan, :title, :start, :align].each do |a|
      atts << " #{a}=\"#{ opts[a] }\"" if opts[a]
    end
    atts
  end
  
  [:h1, :h2, :h3, :h4, :h5, :h6, :p, :pre, :div].each do |m|
    define_method(m) do |opts|
      "<#{m}#{pba(opts)}>#{opts[:text]}</#{m}>\n"
    end
  end
  
  [:strong, :code, :em, :i, :b, :ins, :sup, :sub, :span, :cite].each do |m|
    define_method(m) do |opts|
      opts[:block] = true
      "<#{m}#{pba(opts)}>#{opts[:text]}</#{m}>"
    end
  end
  
  def acronym(opts)
    opts[:block] = true
    "<acronym#{pba(opts)}>#{caps(:text => opts[:text])}</acronym>"
  end
  
  def caps(opts)
    opts[:class] = 'caps'
    span(opts)
  end
  
  def del(opts)
    opts[:block] = true
    "<del#{pba(opts)}>#{opts[:text]}</del>"
  end
  
  def del_phrase(opts)
    " #{del(opts)}"
  end
  
  [:ol, :ul].each do |m|
    define_method("#{m}_open") do |opts|
      opts[:block] = true
      "#{"\n" if opts[:nest] > 1}#{"\t" * (opts[:nest] - 1)}<#{m}#{pba(opts)}>\n"
    end
    define_method("#{m}_close") do |opts|
      "#{li_close}#{"\t" * (opts[:nest] - 1)}</#{m}>#{"\n" if opts[:nest] <= 1}"
    end
  end
  
  def li_open(opts)
    "#{li_close unless opts.delete(:first)}#{"\t" * opts[:nest]}<li#{pba(opts)}>#{opts[:text]}"
  end
  
  def li_close(opts=nil)
    "</li>\n"
  end
  
  def dl_open(opts)
    opts[:block] = true
    "<dl#{pba(opts)}>\n"
  end
  
  def dl_close(opts=nil)
    "</dl>\n"
  end
  
  [:dt, :dd].each do |m|
    define_method(m) do |opts|
      "\t<#{m}#{pba(opts)}>#{opts[:text]}</#{m}>\n"
    end
  end
  
  def ignore(opts)
    opts[:text]
  end
  alias_method :notextile, :ignore
  
  def para(txt)
    "<p>" + txt + "</p>\n"
  end
  
  def td(opts)
    tdtype = opts[:th] ? 'th' : 'td'
    "\t\t<#{tdtype}#{pba(opts)}>#{opts[:text]}</#{tdtype}>\n"
  end
  
  def tr_open(opts)
    "\t<tr#{pba(opts)}>\n"
  end
  
  def tr_close(opts)
    "\t</tr>\n"
  end
  
  def table_open(opts)
    "<table#{pba(opts)}>\n"
  end
  
  def table_close(opts)
    "</table>\n"
  end
  
  def bc_open(opts)
    opts[:block] = true
    "<pre#{pba(opts)}>"
  end
  
  def bc_close(opts)
    "</pre>\n"
  end
  
  def bq_open(opts)
    opts[:block] = true
    cite = opts[:cite] ? " cite=\"#{ opts[:cite] }\"" : ''
    "<blockquote#{cite}#{pba(opts)}>\n"
  end
  
  def bq_close(opts)
    "</blockquote>\n"
  end
  
  def link(opts)
    "<a href=\"#{opts[:href].gsub(/&/, '&#38;')}\"#{pba(opts)}>#{opts[:name]}</a>"
  end
  
  def image(opts)
    opts.delete(:align)
    opts[:alt] = opts[:title]
    img = "<img src=\"#{urlesc opts[:src]}\"#{pba(opts)} alt=\"#{opts[:alt]}\" />"  
    img = "<a href=\"#{urlesc opts[:href]}\">#{img}</a>" if opts[:href]
    img
  end
  
  def footno(opts)
    opts[:id] ||= opts[:text]
    %Q{<sup class="footnote"><a href=\"#fn#{opts[:id]}\">#{opts[:text]}</a></sup>}
  end
  
  def fn(opts)
    no = opts[:id]
    opts[:id] = "fn#{no}"
    opts[:class] = ["footnote", opts[:class]].compact.join(" ")
    "<p#{pba(opts)}><sup>#{no}</sup> #{opts[:text]}</p>\n"
  end
  
  def snip(opts)
    "<pre#{pba(opts)}><code>#{opts[:text]}</code></pre>\n"
  end
  
  def quote1(opts)
    "&#8216;#{opts[:text]}&#8217;"
  end
  
  def quote2(opts)
    "&#8220;#{opts[:text]}&#8221;"
  end
  
  def ellipsis(opts)
    "#{opts[:text]}&#8230;"
  end
  
  def emdash(opts)
    "&#8212;"
  end
  
  def endash(opts)
    " &#8211; "
  end
  
  def arrow(opts)
    "&#8594;"
  end
  
  def dim(opts)
    space = opts[:space] ? " " : ''
    "#{opts[:x]}#{space}&#215;#{space}"
  end
  
  def trademark(opts)
    "&#8482;"
  end
  
  def registered(opts)
    "&#174;"
  end
  
  def copyright(opts)
    "&#169;"
  end
  
  def entity(opts)
    "&#{opts[:text]};"
  end
  
  def urlesc(txt)
    txt.gsub(/&/, '&amp;')
  end
  
  def redcloth_version(opts)
    p(:text => RedCloth::VERSION)
  end
end
