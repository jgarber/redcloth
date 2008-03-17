class << RedCloth::LATEX
  def options
    {:html_escape_entities => false}
  end
  
  def after_transform(text)
    
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
