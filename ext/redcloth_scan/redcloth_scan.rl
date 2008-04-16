/*
 * redcloth_scan.rl
 *
 * Copyright (C) 2008 Jason Garber
 */
#define redcloth_scan_c

#include <ruby.h>
#include "redcloth.h"

VALUE super_ParseError, super_RedCloth, super_HTML, super_LATEX;
int SYM_html_escape_entities;

%%{

  machine redcloth_scan;
  include redcloth_common "ext/redcloth_scan/redcloth_common.rl";

  action extend { extend = rb_hash_aref(regs, ID2SYM(rb_intern("type"))); }

  # blocks
  notextile_tag_start = "<notextile>" ;
  notextile_tag_end = "</notextile>" CRLF? ;
  notextile_line = " " (( default+ ) -- CRLF) CRLF ;
  notextile_block_start = ( "notextile" >A %{ STORE(type) } A C :> "." ( "." %extend | "" ) " "+ ) ;
  pre_tag_start = "<pre" [^>]* ">" (space* "<code>")? ;
  pre_tag_end = ("</code>" space*)? "</pre>" CRLF? ;
  pre_block_start = ( "pre" >A %{ STORE(type) } A C :> "." ( "." %extend | "" ) " "+ ) ;
  bc_start = ( "bc" >A %{ STORE(type) } A C :> "." ( "." %extend | "" ) " "+ ) ;
  bq_start = ( "bq" >A %{ STORE(type) } A C :> "." ( "." %extend | "" ) ( ":" %A uri %{ STORE(cite) } )? " "+ ) ;
  btype = ( "p" | "h1" | "h2" | "h3" | "h4" | "h5" | "h6" | "div" ) ;
  block_start = ( btype >A %{ STORE(type) } A C :> "." ( "." %extend | "" ) " "+ ) ;
  all_btypes = btype | "bq" | "bc" | "pre" | "notextile" ;
  next_block_start = ( all_btypes A_noactions C_noactions :> "."+ " " ) >A @{ p = reg - 1; } ;
  double_return = CRLF{2,} ;
  block_end = ( double_return | EOF );
  ftype = ( "fn" >A %{ STORE(type) } digit+ >A %{ STORE(id) } ) ;
  footnote_start = ( ftype A C :> dotspace ) ;
  ul = "*" %{nest++; list_type = "ul";};
  ol = "#" %{nest++; list_type = "ol";};
  list_start  = ( ( ul | ol )+ N A C :> " "+ ) >{nest = 0;} ;
  dl_start = "-" . " "+ ;
  dd_start = ":=" ;
  long_dd  = dd_start " "* CRLF %{ ADD_BLOCK(); ASET(type, dd); } any+ >A %{ TRANSFORM(text) } :>> "=:" ;
  blank_line = CRLF;
  link_alias = ( "[" >{ ASET(type, ignore) } %A phrase %T "]" %A uri %{ STORE_URL(href); } ) ;
  
  # image lookahead
  IMG_A_LEFT = "<" %{ ASET(float, left) } ;
  IMG_A_RIGHT = ">" %{ ASET(float, right) } ;
  aligned_image = ( "["? "!" (IMG_A_LEFT | IMG_A_RIGHT) ) >A @{ p = reg - 1; } ;
  
  # html blocks
  BlockTagName = Name* - ("pre" | "notextile" | "a" | "applet" | "basefont" | "bdo" | "br" | "font" | "iframe" | "img" | "map" | "object" | "param" | "q" | "script" | "span" | "sub" | "sup" | "abbr" | "acronym" | "cite" | "code" | "del" | "dfn" | "em" | "ins" | "kbd" | "samp" | "strong" | "var" | "b" | "big" | "i" | "s" | "small" | "strike" | "tt" | "u");
  block_start_tag = "<" BlockTagName space+ AttrSet* (AttrEnd)? ">" | "<" BlockTagName ">";
  block_empty_tag = "<" BlockTagName space+ AttrSet* (AttrEnd)? "/>" | "<" BlockTagName "/>" ;
  block_end_tag = "</" BlockTagName space* ">" ;
  html_start = indent (block_start_tag | block_empty_tag) indent ;
  html_end = indent block_end_tag indent CRLF? ;
  standalone_html = indent (block_start_tag | block_empty_tag | block_end_tag) indent CRLF+;

  # tables
  para = ( default+ ) -- CRLF ;
  btext = para ( CRLF{2} )? ;
  tddef = ( D? S A C :> dotspace ) ;
  td = ( tddef? btext >A %T :> "|" >{PASS(table, text, td);} ) >X ;
  trdef = ( A C :> dotspace ) ;
  tr = ( trdef? "|" %{INLINE(table, tr_open);} td+ ) >X %{INLINE(table, tr_close);} ;
  trows = ( tr (CRLF >X tr)* ) ;
  tdef = ( "table" >X A C :> dotspace CRLF ) ;
  table = ( tdef? trows >{INLINE(table, table_open);} ) >{ reg = NULL; } ;

  # info
  redcloth_version = "RedCloth::VERSION" (CRLF* EOF | double_return) ;

  pre_tag := |*
    pre_tag_end         { CAT(block); DONE(block); fgoto main; };
    default => esc_pre;
  *|;
  
  pre_block := |*
    EOF { 
      ADD_BLOCKCODE(); 
      fgoto main; 
    };
    double_return { 
      if (NIL_P(extend)) { 
        ADD_BLOCKCODE(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
      } 
    };
    double_return next_block_start { 
      if (NIL_P(extend)) { 
        ADD_BLOCKCODE(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
        END_EXTENDED(); 
        fgoto main; 
      } 
    };
    default => esc_pre;
  *|;

  script_tag := |*
    script_tag_end     { CAT(block); DONE(block); fgoto main; };
    default => cat;
  *|;

  notextile_tag := |*
    notextile_tag_end   { DONE(block); fgoto main; };
    default => cat;
  *|;
  
  notextile_block := |*
    EOF { 
      DONE(block); 
      fgoto main; 
    };
    double_return { 
      if (NIL_P(extend)) { 
        DONE(block); 
        fgoto main; 
      } else { 
        CAT(block); 
        DONE(block); 
      } 
    };
    double_return next_block_start { 
      if (NIL_P(extend)) { 
        DONE(block); 
        fgoto main; 
      } else { 
        CAT(block); 
        DONE(block); 
        END_EXTENDED(); 
        fgoto main; 
      } 
    };
    default => cat;
  *|;
 
  html := |*
    html_end        { ADD_BLOCK(); CAT(html); fgoto main; };
    default => cat;
  *|;

  bc := |*
    EOF { 
      ADD_BLOCKCODE(); 
      INLINE(html, bc_close); 
      plain_block = rb_str_new2("p"); 
      fgoto main;
    };
    double_return { 
      if (NIL_P(extend)) { 
        ADD_BLOCKCODE(); 
        INLINE(html, bc_close); 
        plain_block = rb_str_new2("p"); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
        CAT(html); 
      } 
    };
    double_return next_block_start { 
      if (NIL_P(extend)) { 
        ADD_BLOCKCODE(); 
        INLINE(html, bc_close); 
        plain_block = rb_str_new2("p"); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCKCODE(); 
        CAT(html); 
        INLINE(html, bc_close); 
        plain_block = rb_str_new2("p");  
        END_EXTENDED(); 
        fgoto main; 
      } 
    };
    default => esc_pre;
  *|;

  bq := |*
    EOF { 
      ADD_BLOCK(); 
      INLINE(html, bq_close); 
      fgoto main; 
    };
    double_return { 
      if (NIL_P(extend)) { 
        ADD_BLOCK(); 
        INLINE(html, bq_close); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
      } 
    };
    double_return next_block_start { 
      if (NIL_P(extend)) { 
        ADD_BLOCK(); 
        INLINE(html, bq_close); 
        fgoto main; 
      } else {
        ADD_EXTENDED_BLOCK(); 
        INLINE(html, bq_close); 
        END_EXTENDED(); 
        fgoto main; 
      }
    };
    default => cat;
  *|;

  block := |*
    EOF { 
      ADD_BLOCK(); 
      fgoto main;
    };
    double_return {
      if (NIL_P(extend)) { 
        ADD_BLOCK(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
      } 
    };
    double_return next_block_start { 
      if (NIL_P(extend)) { 
        ADD_BLOCK(); 
        fgoto main; 
      } else { 
        ADD_EXTENDED_BLOCK(); 
        END_EXTENDED(); 
        fgoto main; 
      }      
    };
    CRLF list_start { 
      ADD_BLOCK(); 
      list_layout = rb_ary_new(); 
      LIST_ITEM(); 
      fgoto list; 
    };
    
    default => cat;
  *|;

  footnote := |*
    block_end       { ADD_BLOCK(); fgoto main; };
    default => cat;
  *|;

  list := |*
    CRLF list_start { ADD_BLOCK(); LIST_ITEM(); };
    block_end       { ADD_BLOCK(); nest = 0; LIST_CLOSE(); fgoto main; };
    default => cat;
  *|;

  dl := |*
    CRLF dl_start   { ADD_BLOCK(); ASET(type, dt); };
    dd_start        { ADD_BLOCK(); ASET(type, dd); };
    long_dd         { INLINE(html, dd); };
    block_end       { ADD_BLOCK(); INLINE(html, dl_close);  fgoto main; };
    default => cat;
  *|;

  main := |*
    notextile_line  { CAT(block); DONE(block); };
    notextile_tag_start { ASET(type, notextile); fgoto notextile_tag; };
    notextile_block_start { fgoto notextile_block; };
    script_tag_start { ASET(type, script); CAT(block); fgoto script_tag; };
    pre_tag_start       { ASET(type, notextile); CAT(block); fgoto pre_tag; };
    pre_block_start { fgoto pre_block; };
    standalone_html { CAT(block); DONE(block); };
    html_start      { ASET(type, notextile); CAT(html); fgoto html; };
    bc_start        { INLINE(html, bc_open); ASET(type, code); plain_block = rb_str_new2("code"); fgoto bc; };
    bq_start        { INLINE(html, bq_open); ASET(type, p); fgoto bq; };
    block_start     { fgoto block; };
    footnote_start  { fgoto footnote; };
    list_start      { list_layout = rb_ary_new(); LIST_ITEM(); fgoto list; };
    dl_start        { INLINE(html, dl_open); ASET(type, dt); fgoto dl; };
    table           { INLINE(table, table_close); DONE(table); fgoto block; };
    link_alias      { rb_hash_aset(refs_found, rb_hash_aref(regs, ID2SYM(rb_intern("text"))), rb_hash_aref(regs, ID2SYM(rb_intern("href")))); DONE(block); };
    aligned_image   { rb_hash_aset(regs, ID2SYM(rb_intern("type")), plain_block); fgoto block; };
    redcloth_version { INLINE(html, redcloth_version); };
    blank_line => cat;
    default
    { 
      regs = rb_hash_new();
      rb_hash_aset(regs, ID2SYM(rb_intern("type")), plain_block);
      CAT(block);
      fgoto block;
    };
    EOF;
  *|;

}%%

%% write data nofinal;

VALUE
redcloth_transform(rb_formatter, p, pe, refs)
  VALUE rb_formatter;
  char *p, *pe;
  VALUE refs;
{
  char *orig_p = p, *orig_pe = pe;
  int cs, act, nest;
  char *ts = NULL, *te = NULL, *reg = NULL, *eof = NULL;
  VALUE html = rb_str_new2("");
  VALUE table = rb_str_new2("");
  VALUE block = rb_str_new2("");
  VALUE regs = rb_hash_new();
  VALUE list_layout = Qnil;
  char *list_type = NULL;
  VALUE list_index = rb_ary_new();
  int list_continue = 0;
  VALUE plain_block = rb_str_new2("p");
  VALUE extend = Qnil;
  char listm[10] = "";
  VALUE refs_found = rb_hash_new();
  unsigned int opts = 0;
  
  VALUE options = rb_funcall(rb_formatter, rb_intern("options"), 0);
  Check_Type(options, T_HASH);
  if (rb_hash_aref(options, SYM_html_escape_entities) == Qtrue) opts |= SR_HTML_ESCAPE_ENTITIES;

  %% write init;

  %% write exec;

  if (RSTRING(block)->len > 0)
  {
    ADD_BLOCK();
  }

  if ( NIL_P(refs) && rb_funcall(refs_found, rb_intern("empty?"), 0) == Qfalse ) {
    return redcloth_transform(rb_formatter, orig_p, orig_pe, refs_found);
  } else {
    rb_funcall(rb_formatter, rb_intern("after_transform"), 1, html);
    return html;
  }
}

VALUE
redcloth_transform2(formatter, str)
  VALUE formatter, str;
{
  rb_str_cat2(str, "\n");
  StringValue(str);
  return redcloth_transform(formatter, RSTRING(str)->ptr, RSTRING(str)->ptr + RSTRING(str)->len + 1, Qnil);
}

/*
 * Generates HTML from the Textile contents.
 *
 *   r = RedCloth.new( "And then? She *fell*!" )
 *   r.to_html
 *     #=>"And then? She <strong>fell</strong>!"
 */
static VALUE
redcloth_to_html(self)
  VALUE self;
{
  char *pe, *p;
  int len = 0;

  return redcloth_transform2(super_HTML, self);
}

/*
 * Generates LaTeX from the Textile contents.
 *
 *   r = RedCloth.new( "And then? She *fell*!" )
 *   r.to_latex
 *     #=>"And then? She \\textbf{fell}!\n\n"
 */
static VALUE
redcloth_to_latex(self)
  VALUE self;
{
  char *pe, *p;
  int len = 0;

  return redcloth_transform2(super_LATEX, self);
}

static VALUE
redcloth_to(self, formatter)
  VALUE self, formatter;
{
  char *pe, *p;
  int len = 0;

  return redcloth_transform2(formatter, self);
}

void Init_redcloth_scan()
{
 /* The RedCloth parser. See the README for Textile syntax. */
  super_RedCloth = rb_define_class("RedCloth", rb_cString);
  rb_define_method(super_RedCloth, "to_html", redcloth_to_html, 0);
  rb_define_method(super_RedCloth, "to_latex", redcloth_to_latex, 0);
  rb_define_method(super_RedCloth, "to", redcloth_to, 1);
  super_ParseError = rb_define_class_under(super_RedCloth, "ParseError", rb_eException);
  /* RedCloth HTML formatter. */
  super_HTML  = rb_define_module_under(super_RedCloth, "HTML");
  /* RedCloth LaTeX formatter. */
  super_LATEX = rb_define_module_under(super_RedCloth, "LATEX");
  SYM_html_escape_entities = ID2SYM(rb_intern("html_escape_entities"));
}
