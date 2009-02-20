require 'yaml' 

module RedCloth::Formatters::LATEX
  include RedCloth::Formatters::Base
  
  ENTITIES = YAML::load(File.read(File.dirname(__FILE__)+'/latex_entities.yml')) 

  module Settings
    # Maps CSS style names to latex formatting options
    def latex_image_styles
      @latex_image_class_styles ||= {}
    end
  end

  RedCloth::TextileDoc.send(:include, Settings)
  
  # headers
  { :h1 => 'section*',
    :h2 => 'subsection*',
    :h3 => 'subsubsection*',
    :h4 => 'textbf',
    :h5 => 'textbf',
    :h6 => 'textbf',
  }.each do |m,tag| 
    define_method(m) do |opts| 
      "\\#{tag}{#{opts[:text]}}\n\n" 
    end 
  end 
  
  # commands 
  { :strong => 'textbf',
    :em => 'emph',
    :i  => 'textit',
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
      begin_chunk(env) + opts[:text] + end_chunk(env)
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
  
  def p(opts)
    opts[:text] + "\n\n"
  end
  
  def td(opts)
    column = @table_row.size
    if opts[:colspan]
      opts[:text] = "\\multicolumn{#{opts[:colspan]}}{ #{"l " * opts[:colspan].to_i}}{#{opts[:text]}}"
    end
    if opts[:rowspan]
      @table_multirow_next[column] = opts[:rowspan].to_i - 1
      opts[:text] = "\\multirow{#{opts[:rowspan]}}{*}{#{opts[:text]}}"
    end
    @table_row.push(opts[:text])
    return ""
  end
  
  def tr_open(opts)
    @table_row = []
    return ""
  end
  
  def tr_close(opts)
    multirow_columns = @table_multirow.find_all {|c,n| n > 0}
    multirow_columns.each do |c,n|
      @table_row.insert(c,"")
      @table_multirow[c] -= 1
    end
    @table_multirow.merge!(@table_multirow_next)
    @table_multirow_next = {}
    @table.push(@table_row)
    return ""
  end
  
  # We need to know the column count before opening tabular context.
  def table_open(opts)
    @table = []
    @table_multirow = {}
    @table_multirow_next = {}
    return ""
  end
  
  def table_close(opts)
    output = "\\begin{tabular}{ #{"l " * @table[0].size }}\n"
    @table.each do |row|
      output << "  #{row.join(" & ")} \\\\\n"
    end
    output << "\\end{tabular}\n"
    output
  end

  def bc_open(opts)
    opts[:block] = true
    begin_chunk("verbatim") + "\n"
  end

  def bc_close(opts)
    end_chunk("verbatim") + "\n"
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
  #
  # Remember to use '\RequirePackage{graphicx}' in your LaTeX header
  # 
  # FIXME: Look at dealing with width / height gracefully as this should be 
  # specified in a unit like cm rather than px.
  def image(opts)
    # Don't know how to use remote links, plus can we trust them?
    return "" if opts[:src] =~ /^\w+\:\/\//
    # Resolve CSS styles if any have been set
    styling = opts[:class].to_s.split(/\s+/).collect { |style| latex_image_styles[style] }.compact.join ','
    # Build latex code
    [ "\\begin{figure}[htp]",
      "  \\includegraphics[#{styling}]{#{opts[:src]}}",
     ("  \\caption{#{escape opts[:title]}}" if opts[:title]),
     ("  \\label{#{escape opts[:alt]}}" if opts[:alt]),
      "\\end{figure}",
    ].compact.join "\n"
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
    "#{opts[:text]}\\ldots{}"
  end
  
  def emdash(opts)
    "---"
  end
  
  def endash(opts)
    "--"
  end
  
  def arrow(opts)
    "\\rightarrow{}"
  end
  
  def trademark(opts)
    "\\texttrademark{}"
  end
  
  def registered(opts)
    "\\textregistered{}"
  end
  
  def copyright(opts)
    "\\copyright{}"
  end
  
  # TODO: what do we do with (unknown) unicode entities ? 
  #
  def entity(opts)
    text = opts[:text][0..0] == '#' ? opts[:text][1..-1] : opts[:text] 
    ENTITIES[text]
  end
  
  def dim(opts)
    opts[:text].gsub!('x', '\times')
    opts[:text].gsub!('"', "''")
    period = opts[:text].slice!(/\.$/)
    "$#{opts[:text]}$#{period}"
  end
  
  private
  
  def escape(text)
    latex_esc(text)
  end

  def escape_pre(text)
    text
  end
  
  # Use this for block level commands that use \begin
  def begin_chunk(type)
    chunk_counter[type] += 1
    return "\\begin{#{type}}" if 1 == chunk_counter[type]
    ''
  end
  
  # Use this for block level commands that use \end
  def end_chunk(type)
    chunk_counter[type] -= 1
    raise RuntimeError, "Bad latex #{type} nesting detected" if chunk_counter[type] < 0 # This should never need to happen
    return "\\end{#{type}}" if 0 == chunk_counter[type]
    ''
  end
  
  def chunk_counter
    @chunk_counter ||= Hash.new 0
  end
end
