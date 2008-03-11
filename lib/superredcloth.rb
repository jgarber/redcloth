require 'superredcloth_scan'

class << SuperRedCloth::HTML
  def options
    {:html_escape_entities => true}
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
  
  [:h1, :h2, :h3, :h4, :h5, :h6, :p, :pre, :div, :dt, :dd].each do |m|
    define_method(m) do |opts|
      "<#{m}#{pba(opts)}>#{opts[:text]}</#{m}>"
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
      "<#{m}#{pba(opts)}>\n"
    end
    define_method("#{m}_close") do |opts|
      "#{li_close}</#{m}>"
    end
  end
  
  def li_open(opts)
    "#{li_close unless opts.delete(:first)}\t<li#{pba(opts)}>#{opts[:text]}"
  end
  
  def li_close(opts=nil)
    "</li>\n"
  end
  
  def dl_open(opts)
    opts[:block] = true
    "<dl#{pba(opts)}>\n"
  end
  
  def dl_close(opts=nil)
    "</dl>"
  end
  
  def ignore(opts)
    opts[:text]
  end
  alias_method :notextile, :ignore
  
  def para(txt)
    "<p>" + txt + "</p>"
  end
  
  def td(opts)
    tdtype = opts[:th] ? 'th' : 'td'
    "\t\t\t<#{tdtype}#{pba(opts)}>#{opts[:text]}</#{tdtype}>\n"
  end
  
  def tr_open(opts)
    "\t\t<tr#{pba(opts)}>\n"
  end
  
  def tr_close(opts)
    "\t\t</tr>\n"
  end
  
  def table_open(opts)
    "<table#{pba(opts)}>\n"
  end
  
  def table_close(opts)
    "\t</table>"
  end
  
  def bc_open(opts)
    opts[:block] = true
    "<pre#{pba(opts)}>"
  end
  
  def bc_close(opts)
    "</pre>"
  end
  
  def bq_open(opts)
    opts[:block] = true
    cite = opts[:cite] ? " cite=\"#{ opts[:cite] }\"" : ''
    "<blockquote#{cite}#{pba(opts)}>"
  end
  
  def bq_close(opts)
    "</blockquote>"
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
    "<p#{pba(opts)}><sup>#{no}</sup> #{opts[:text]}</p>"
  end
  
  def snip(opts)
    "<pre#{pba(opts)}><code>#{opts[:text]}</code></pre>"
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
end


class << SuperRedCloth::LATEX
  def options
    {:html_escape_entities => false}
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
  
  # commands
  { :h1 => 'section*',
    :h2 => 'subsection*',
    :h3 => 'subsubsection*',
    :h4 => 'textbf',
    :h5 => 'textbf',
    :h6 => 'textbf',
    :strong => 'textbf',
    :em => 'emph',
    :i  => 'emph',
    :b  => 'textbf',
    :ins => 'underline',
    :del => 'sout',
    :acronym => 'MakeUppercase',
    :caps => 'MakeUppercase',
    }.each do |m,tag|
    define_method(m) do |opts|
      "\\#{tag}{#{opts[:text]}}"
    end
  end
  
  { :sup => '\ensuremath{^\textrm{#1}}',
    :sub => '\ensuremath{_\textrm{#1}}',
  }.each do |m, expr|
    define_method(m) do |opts|
      expr.sub('#1', opts[:text])
    end
  end
  
  # environments
  { :pre  => 'verbatim',
    :code => 'verbatim',
    :cite => 'quote',
    }.each do |m, env|
    define_method(m) do |opts|
      "\\begin{#{env}}#{opts[:text]}\\end{#{env}}"
    end
  end
  
  # ignore (or find a good solution later)
  [ :span,
    :div,
    ].each do |m|
    define_method(m) do |opts|
      opts[:text].to_s
    end
  end
  
  def del_phrase(opts)
    " #{del(opts)}"
  end
  
  { :ol => 'enumerate',
    :ul => 'itemize',
    }.each do |m, env|
    define_method("#{m}_open") do |opts|
      opts[:block] = true
      "\\begin{#{env}}\n"
    end
    define_method("#{m}_close") do |opts|
      "#{li_close}\\end{#{env}}\n\n"
    end
  end
  
  def li_open(opts)
    "#{li_close unless opts.delete(:first)}\t\\item #{opts[:text]}"
  end
  
  def li_close(opts=nil)
    "\n"
  end
  
  def ignore(opts)
    opts[:text]
  end
  alias_method :notextile, :ignore
  
  def para(txt)
    txt
  end
  
  def p(opts)
    opts[:text] + "\n\n"
  end
  
  def td(opts)
    "\t\t\t#{opts[:text]} &\n"
  end
  
  def tr_open(opts)
    "\t\t"
  end
  
  def tr_close(opts)
    "\t\t\\\\\n"
  end
  
  # FIXME: we need to know the column count before opening tabular context.
  def table_open(opts)
    "\\begin{align*}\n"
  end
  
  def table_close(opts)
    "\t\\end{align*}\n"
  end

  def bc_open(opts)
    opts[:block] = true
    "\\begin{verbatim}\n"
  end

  def bc_close(opts)
    "\\end{verbatim}\n"
  end

  def bq_open(opts)
    opts[:block] = true
    "\\begin{quotation}\n"
  end

  def bq_close(opts)
    "\\end{quotation}\n\n"
  end
  
  def link(opts)
    "\\href{#{opts[:href]}}{#{opts[:name]}}"
  end
  
  # FIXME: use includegraphics with security verification
  def image(opts)
    ""
  end
  
  def footno(opts)
    # TODO: insert a placeholder until we know the footnote content.
    # For this to work, we need some kind of post-processing...
    "\\footnotemark[#{opts[:text]}]"
  end
  
  def fn(opts)
    "\\footnotetext[#{opts[:id]}]{#{opts[:text]}}"
  end
  
  def snip(opts)
    "\\begin{verbatim}#{opts[:text]}\\end{verbatim}"
  end
  
  def quote1(opts)
    "`#{opts[:text]}'"
  end
  
  def quote2(opts)
    "``#{opts[:text]}\""
  end
  
  def ellipsis(opts)
    "#{opts[:text]}\\ldots"
  end
  
  # TODO: these should use Latex equivalents
  def emdash(opts)
    "--"
  end
  
  def endash(opts)
    " - "
  end
  
  def arrow(opts)
    "\\rightarrow"
  end
  
  def trademark(opts)
    "\\texttrademark"
  end
  
  def registered(opts)
    "\\textregistered"
  end
  
  def copyright(opts)
    "\\copyright"
  end
  
  # TODO: what do we do with unicode entities ?
  def entity(opts)
    "&#{opts[:text]}"
  end
  
  # ?
  def dim(opts)
    space = opts[:space] ? " " : ''
    "#{opts[:x]}#{space}&#215;#{space}"
  end
end