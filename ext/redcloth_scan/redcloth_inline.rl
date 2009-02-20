/*
 * redcloth_inline.rl
 *
 * Copyright (C) 2009 Jason Garber
 */
%%{

  machine redcloth_inline;

  # links
  mtext_noquotes = mtext -- '"' ;
  quoted_mtext = '"' mtext_noquotes '"' ;
  mtext_including_quotes = (mtext_noquotes ' "' mtext_noquotes '" ' mtext_noquotes?)+ ;
  link_says = ( C_noactions "."* " "* ((quoted_mtext | mtext_including_quotes | mtext_noquotes) -- '":') ) >A %{ STORE("name"); } ;
  link_says_noquotes_noactions = ( C_noquotes_noactions "."* " "* ((mtext_noquotes) -- '":') ) ;
  link = ( '"' link_says '":' %A uri %{ STORE_URL("href"); } ) >X ;
  link_noquotes_noactions = ( '"' link_says_noquotes_noactions '":' uri ) ;
  bracketed_link = ( '["' link_says '":' %A uri %{ STORE("href"); } :> "]" ) >X ;

  # images
  image_title = ( '(' mtext ')' ) ;
  image_is = ( A2 C ". "? (uri image_title?) >A %{ STORE("src"); } ) ;
  image_link = ( ":" uri >A %{ STORE_URL("href"); } ) ;
  image = ( "!" image_is "!" %A image_link? ) >X ;
  bracketed_image = ( "[!" image_is "!" %A image_link? "]" ) >X ;

  # footnotes
  footno = "[" >X %A digit+ %T "]" ;

  # markup
  end_markup_phrase = (" " | PUNCT | EOF | LF) @{ fhold; };
  code = "["? "@" >X mtext >A %T :> "@" "]"? ;
  script_tag = ( "<script" [^>]* ">" (default+ -- "</script>") "</script>" LF? ) >X >A %T ;
  strong = "["? "*" >X mtext >A %T :> "*" "]"? ;
  b = "["? "**" >X mtext >A %T :> "**" "]"? ;
  em = "["? "_" >X mtext >A %T :> "_" "]"? ;
  i = "["? "__" >X mtext >A %T :> "__" "]"? ;
  del = "[-" >X C ( mtext ) >A %T :>> "-]" ;
  emdash_parenthetical_phrase_with_spaces = " -- " mtext " -- " ;
  del_phrase = (( " " >A %{ STORE("beginning_space"); } "-" | "-" when starts_line) >X C ( mtext ) >A %T :>> ( "-" end_markup_phrase )) - emdash_parenthetical_phrase_with_spaces ;
  ins = "["? "+" >X mtext >A %T :> "+" "]"? ;
  sup = "[^" >X mtext >A %T :> "^]" ;
  sup_phrase = ( "^" when starts_phrase) >X ( mtext ) >A %T :>> ( "^" end_markup_phrase ) ;
  sub = "[~" >X mtext >A %T :> "~]" ;
  sub_phrase = ( "~" when starts_phrase) >X ( mtext ) >A %T :>> ( "~" end_markup_phrase ) ;
  span = "[%" >X mtext >A %T :> "%]" ;
  span_phrase = (("%" when starts_phrase) >X ( mtext ) >A %T :>> ( "%" end_markup_phrase )) ;
  cite = "["? "??" >X mtext >A %T :> "??" "]"? ;
  ignore = "["? "==" >X %A mtext %T :> "==" "]"? ;
  snip = "["? "```" >X %A mtext %T :> "```" "]"? ;
  
  # quotes
  quote1 = "'" >X %A mtext %T :> "'" ;
  non_quote_chars_or_link = (chars -- '"') | link_noquotes_noactions ;
  mtext_inside_quotes = ( non_quote_chars_or_link (mspace non_quote_chars_or_link)* ) ;
  html_tag_up_to_attribute_quote = "<" Name space+ NameAttr space* "=" space* ;
  quote2 = ('"' >X %A ( mtext_inside_quotes - (mtext_inside_quotes html_tag_up_to_attribute_quote ) ) %T :> '"' ) ;
  multi_paragraph_quote = (('"' when starts_line) >X  %A ( chars -- '"' ) %T );
  
  # html
  start_tag = ( "<" Name space+ AttrSet* (AttrEnd)? ">" | "<" Name ">" ) >X >A %T ;
  empty_tag = ( "<" Name space+ AttrSet* (AttrEnd)? "/>" | "<" Name "/>" ) >X >A %T ;
  end_tag = ( "</" Name space* ">" ) >X >A %T ;
  html_comment = ("<!--" (default+) :>> "-->") >X >A %T;

  # glyphs
  ellipsis = ( " "? >A %T "..." ) >X ;
  emdash = "--" ;
  arrow = "->" ;
  endash = " - " ;
  acronym = ( [A-Z] >A [A-Z0-9]{2,} %T "(" default+ >A %{ STORE("title"); } :> ")" ) >X ;
  caps_noactions = upper{3,} ;
  caps = ( caps_noactions >A %*T ) >X ;
  dim_digit = [0-9.]+ ;
  prime = ("'" | '"')?;
  dim_noactions = dim_digit prime (("x" | " x ") dim_digit prime) %T (("x" | " x ") dim_digit prime)? ;
  dim = dim_noactions >X >A %T ;
  tm = [Tt] [Mm] ;
  trademark = " "? ( "[" tm "]" | "(" tm ")" ) ;
  reg = [Rr] ;
  registered = " "? ( "[" reg "]" | "(" reg ")" ) ;
  cee = [Cc] ;
  copyright = ( "[" cee "]" | "(" cee ")" ) ;
  entity = ( "&" %A ( '#' digit+ | ( alpha ( alpha | digit )+ ) ) %T ';' ) >X ;
  
  # info
  redcloth_version = "[RedCloth::VERSION]" ;

  other_phrase = phrase -- dim_noactions;

  code_tag := |*
    code_tag_end { CAT(block); fgoto main; };
    default => esc_pre;
  *|;

  main := |*
    
    image { PARSE_IMAGE_ATTR("src"); INLINE(block, "image"); };
    bracketed_image { PARSE_IMAGE_ATTR("src"); INLINE(block, "image"); };
    
    link { PARSE_LINK_ATTR("name"); PASS(block, "name", "link"); };
    bracketed_link { PARSE_LINK_ATTR("name"); PASS(block, "name", "link"); };
    
    code { PARSE_ATTR("text"); PASS_CODE(block, "text", "code", opts); };
    code_tag_start { CAT(block); fgoto code_tag; };
    notextile { INLINE(block, "notextile"); };
    strong { PARSE_ATTR("text"); PASS(block, "text", "strong"); };
    b { PARSE_ATTR("text"); PASS(block, "text", "b"); };
    em { PARSE_ATTR("text"); PASS(block, "text", "em"); };
    i { PARSE_ATTR("text"); PASS(block, "text", "i"); };
    del { PASS(block, "text", "del"); };
    del_phrase { PASS(block, "text", "del_phrase"); };
    ins { PARSE_ATTR("text"); PASS(block, "text", "ins"); };
    sup { PARSE_ATTR("text"); PASS(block, "text", "sup"); };
    sup_phrase { PARSE_ATTR("text"); PASS(block, "text", "sup_phrase"); };
    sub { PARSE_ATTR("text"); PASS(block, "text", "sub"); };
    sub_phrase { PARSE_ATTR("text"); PASS(block, "text", "sub_phrase"); };
    span { PARSE_ATTR("text"); PASS(block, "text", "span"); };
    span_phrase { PARSE_ATTR("text"); PASS(block, "text", "span_phrase"); };
    cite { PARSE_ATTR("text"); PASS(block, "text", "cite"); };
    ignore => ignore;
    snip { PASS(block, "text", "snip"); };
    quote1 { PASS(block, "text", "quote1"); };
    quote2 { PASS(block, "text", "quote2"); };
    multi_paragraph_quote { PASS(block, "text", "multi_paragraph_quote"); };
    
    ellipsis { INLINE(block, "ellipsis"); };
    emdash { INLINE(block, "emdash"); };
    endash { INLINE(block, "endash"); };
    arrow { INLINE(block, "arrow"); };
    caps { INLINE(block, "caps"); };
    acronym { INLINE(block, "acronym"); };
    dim { INLINE(block, "dim"); };
    trademark { INLINE(block, "trademark"); };
    registered { INLINE(block, "registered"); };
    copyright { INLINE(block, "copyright"); };
    footno { PASS(block, "text", "footno"); };
    entity { INLINE(block, "entity"); };
    
    script_tag { INLINE(block, "inline_html"); };
    start_tag { INLINE(block, "inline_html"); };
    end_tag { INLINE(block, "inline_html"); };
    empty_tag { INLINE(block, "inline_html"); };
    html_comment { INLINE(block, "inline_html"); };
    
    redcloth_version { INLINE(block, "inline_redcloth_version"); };
    
    other_phrase => esc;
    PUNCT => esc;
    space => esc;
    
    EOF;
    
  *|;

}%%;
