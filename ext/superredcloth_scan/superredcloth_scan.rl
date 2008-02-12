/*
 * superredcloth_scan.rl
 *
 * $Author: why $
 * $Date$
 *
 * Copyright (C) 2007 why the lucky stiff
 */
#define superredcloth_scan_c

#include <ruby.h>
#include "superredcloth.h"

VALUE super_ParseError, super_RedCloth, super_HTML;

%%{

  machine superredcloth_scan;
  include superredcloth_common "ext/superredcloth_scan/superredcloth_common.rl";

  action notextile { rb_str_append(html, rb_funcall(rb_formatter, rb_intern("ignore"), 1, regs)); }
  action extend { plain_block = rb_hash_aref(regs, ID2SYM(rb_intern("type"))); }
  action no_extend { plain_block = rb_str_new2("p"); }

  # blocks
  notextile_start = "<notextile>" ;
  notextile_end = "</notextile>" ;
  notextile_line = " " (( default+ ) -- CRLF) CRLF ;
  pre_start = "<pre" [^>]* ">" (space* "<code>")? ;
  pre_end = ("</code>" space*)? "</pre>" ;
  bc_start = ( "bc" A C :> "." ( "." %extend | "" %no_extend ) " "+ ) ;
  btype = ( "p" | "h1" | "h2" | "h3" | "h4" | "h5" | "h6" | "bq" | "bc" | "pre" | "notextile" | "div" ) >A %{ STORE(type) } ;
  block_start = ( btype A C :> "." ( "." %extend | "" %no_extend ) " "+ ) ;
  block_end = ( CRLF{2} | EOF );
  ftype = ( "fn" >A %{ STORE(type) } digit+ >A %{ STORE(id) } ) ;
  footnote_start = ( ftype A C :> dotspace ) ;
  ul = "*" %{nest++; list_type = "ul";};
  ol = "#" %{nest++; list_type = "ol";};
  list_start  = ( ( ul | ol )+ N A C :> " "+ ) >{nest = 0;} ;
  
  # html blocks
  BlockTagName = Name* - ("pre" | "notextile" | "a" | "applet" | "basefont" | "bdo" | "br" | "font" | "iframe" | "img" | "map" | "object" | "param" | "q" | "script" | "span" | "sub" | "sup" | "abbr" | "acronym" | "cite" | "code" | "del" | "dfn" | "em" | "ins" | "kbd" | "samp" | "strong" | "var" | "b" | "big" | "i" | "s" | "small" | "strike" | "tt" | "u");
  block_start_tag = "<" BlockTagName space+ AttrSet* (AttrEnd)? ">" | "<" BlockTagName ">";
  block_empty_tag = "<" BlockTagName space+ AttrSet* (AttrEnd)? "/>" | "<" BlockTagName "/>" ;
  block_end_tag = "</" BlockTagName space* ">" ;
  html_start = indent (block_start_tag | block_empty_tag) indent ;
  html_end = indent block_end_tag indent CRLF* ;
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

  bc := |*
    block_end       { ADD_BLOCKCODE(); fgoto main; };
    default => esc_pre;
  *|;

  pre := |*
    pre_end         { CAT(block); DONE(block); fgoto main; };
    default => esc_pre;
  *|;

  notextile := |*
    notextile_end   { DONE(block); fgoto main; };
    default => cat;
  *|;
 
  html := |*
    html_end        { CAT(block); ADD_BLOCK(); fgoto main; };
    default => cat;
  *|;

  block := |*
    block_end       { ADD_BLOCK(); fgoto main; };
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

  main := |*
    notextile_line  { CAT(block); DONE(block); };
    notextile_start { ASET(type, notextile); fgoto notextile; };
    pre_start       { ASET(type, notextile); CAT(block); fgoto pre; };
    standalone_html { CAT(block); DONE(block); };
    html_start      { ASET(type, notextile); CAT(block); fgoto html; };
    bc_start        { ASET(type, bc); fgoto bc; };
    block_start     { fgoto block; };
    footnote_start  { fgoto footnote; };
    list_start      { list_layout = rb_ary_new(); LIST_ITEM(); fgoto list; };
    table           { INLINE(table, table_close); DONE(table); fgoto block; };
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
superredcloth_transform(rb_formatter, p, pe)
  VALUE rb_formatter;
  char *p, *pe;
{
  int cs, act, nest;
  char *tokstart = NULL, *tokend = NULL, *reg = NULL;
  VALUE html = rb_str_new2("");
  VALUE table = rb_str_new2("");
  VALUE block = rb_str_new2("");
  VALUE regs = rb_hash_new();
  VALUE list_layout = Qnil;
  char *list_type = NULL;
  VALUE list_index = rb_ary_new();
  int list_continue = 0;
  VALUE plain_block = rb_str_new2("p");
  char listm[10] = "";

  %% write init;

  %% write exec;

  if (RSTRING(block)->len > 0)
  {
    ADD_BLOCK();
  }

  return html;
}

VALUE
superredcloth_transform2(formatter, str)
  VALUE formatter, str;
{
  rb_str_cat2(str, "\n");
  StringValue(str);
  return superredcloth_transform(formatter, RSTRING(str)->ptr, RSTRING(str)->ptr + RSTRING(str)->len + 1);
}

static VALUE
superredcloth_to_html(self)
  VALUE self;
{
  char *pe, *p;
  int len = 0;

  return superredcloth_transform2(super_HTML, self);
}

static VALUE
superredcloth_to(self, formatter)
  VALUE self, formatter;
{
  char *pe, *p;
  int len = 0;

  return superredcloth_transform2(formatter, self);
}

void Init_superredcloth_scan()
{
  super_RedCloth = rb_define_class("SuperRedCloth", rb_cString);
  rb_define_method(super_RedCloth, "to_html", superredcloth_to_html, 0);
  rb_define_method(super_RedCloth, "to", superredcloth_to, 1);
  super_ParseError = rb_define_class_under(super_RedCloth, "ParseError", rb_eException);
  super_HTML = rb_define_module_under(super_RedCloth, "HTML");
}
