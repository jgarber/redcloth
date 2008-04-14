/*
 * redcloth_inline.rl
 *
 * Copyright (C) 2008 Jason Garber
 */
#include <ruby.h>
#include "redcloth.h"

%%{

  machine redcloth_inline;
  include redcloth_common "ext/redcloth_scan/redcloth_common.rl";

  # common
  title = ( '(' default+ >A %{ STORE(title) } :> ')' ) ;
  word = ( alnum | safe | " " ) ;
  mspace = ( ( " " | "\t" | CRLF )+ ) -- CRLF{2} ;
  mtext = ( chars (mspace chars)* ) ;

  # links
  link_says = ( mtext+ ) >A %{ STORE(name) } ;
  link = ( "["? '"' C "."* " "* link_says " "* :> title? :> '":' %A uri %{ STORE_URL(href); } :> "]"? ) >X ;

  # images
  image_src = ( uri ) >A %{ STORE(src) } ;
  image_is = ( A2 C ". "? image_src :> title? ) ;
  image_link = ( ":" uri >A %{ STORE_URL(href); } ) ;
  image = ( "["? "!" image_is "!" %A image_link? "]"? ) >X ;

  # footnotes
  footno = "[" >X %A digit+ %T "]" ;

  # markup
  code = "["? "@" >X C mtext >A %T :> "@" "]"? ;
  code_tag_start = "<code>" ;
  code_tag_end = "</code>" ;
  strong = "["? "*" >X C mtext >A %T :> "*" "]"? ;
  b = "["? "**" >X C mtext >A %T :> "**" "]"? ;
  em = "["? "_" >X C mtext >A %T :> "_" "]"? ;
  i = "["? "__" >X C mtext >A %T :> "__" "]"? ;
  del = "[-" >X C ( mtext ) >A %T :>> "-]" ;
  del_phrase = (" -") >X C ( mtext ) >A %T :>> ( "-" (" " | PUNCT) @{ fhold; } ) ;
  ins = "["? "+" >X C mtext >A %T :> "+" "]"? ;
  sup = "["? "^" >X C mtext >A %T :> "^" "]"? ;
  sub = "["? "~" >X C mtext >A %T :> "~" "]"? ;
  span = "["? "%" >X C mtext >A %T :> "%" "]"? ;
  cite = "["? "??" >X C mtext >A %T :> "??" "]"? ;
  ignore = "["? "==" >X %A mtext %T :> "==" "]"? ;
  snip = "["? "```" >X %A mtext %T :> "```" "]"? ;
  quote1 = "["? "'" >X %A mtext %T :> "'" "]"? ;
  quote2 = "["? '"' >X %A mtext %T :> '"' "]"? ;

  # glyphs
  ellipsis = ( " "? >A %T "..." ) >X ;
  emdash = "--" ;
  arrow = "->" ;
  endash = " - " ;
  acronym = ( [A-Z] >A [A-Z0-9]{2,} %T "(" default+ >A %{ STORE(title) } :> ")" ) >X ;
  caps = ( upper{3,} >A %*T ) >X ;
  dim = ( digit+ >A %{ STORE(x) } (" x " @{ ASET(space, true)} | "x") digit @{ fhold; } ) >X ;
  dim_noactions = digit+ ( (" x " | "x") digit+ )+ ;
  tm = [Tt] [Mm] ;
  trademark = " "? ( "[" tm "]" | "(" tm ")" ) ;
  reg = [Rr] ;
  registered = " "? ( "[" reg "]" | "(" reg ")" ) ;
  cee = [Cc] ;
  copyright = ( "[" cee "]" | "(" cee ")" ) ;
  entity = ( "&" %A ( '#' digit+ | alpha+ ) %T ';' ) >X ;

  other_phrase = phrase -- dim_noactions;

  code_tag := |*
    code_tag_end { CAT(block); fgoto main; };
    default => esc_pre;
  *|;

  script_tag := |*
    script_tag_end { CAT(block); fgoto main; };
    default => cat;
  *|;

  main := |*

    image { INLINE(block, image); };

    link { PASS(block, name, link); };

    code { PASS_CODE(block, text, code, opts); };
    code_tag_start { CAT(block); fgoto code_tag; };
    strong { PASS(block, text, strong); };
    b { PASS(block, text, b); };
    em { PASS(block, text, em); };
    i { PASS(block, text, i); };
    del { PASS(block, text, del); };
    del_phrase { PASS(block, text, del_phrase); };
    ins { PASS(block, text, ins); };
    sup { PASS(block, text, sup); };
    sub { PASS(block, text, sub); };
    span { PASS(block, text, span); };
    cite { PASS(block, text, cite); };
    ignore => ignore;
    snip { PASS(block, text, snip); };
    quote1 { PASS(block, text, quote1); };
    quote2 { PASS(block, text, quote2); };

    ellipsis { INLINE(block, ellipsis); };
    emdash { INLINE(block, emdash); };
    endash { INLINE(block, endash); };
    arrow { INLINE(block, arrow); };
    caps { INLINE(block, caps); };
    acronym { INLINE(block, acronym); };
    dim { INLINE(block, dim); };
    trademark { INLINE(block, trademark); };
    registered { INLINE(block, registered); };
    copyright { INLINE(block, copyright); };
    footno { PASS(block, text, footno); };
    entity { INLINE(block, entity); };

    script_tag_start { CAT(block); fgoto script_tag; };
    start_tag => cat;
    end_tag => cat;
    empty_tag => cat;
    html_comment => cat;

    other_phrase => esc;
    PUNCT => esc;
    space => esc;

    EOF;

  *|;

}%%

%% write data nofinal;

VALUE
red_pass(VALUE rb_formatter, VALUE regs, VALUE ref, ID meth, VALUE refs)
{
  VALUE txt = rb_hash_aref(regs, ref);
  if (!NIL_P(txt)) rb_hash_aset(regs, ref, redcloth_inline2(rb_formatter, txt, refs));
  return rb_funcall(rb_formatter, meth, 1, regs);
}

VALUE
red_pass_code(VALUE rb_formatter, VALUE regs, VALUE ref, ID meth, unsigned int opts)
{
  VALUE txt = rb_hash_aref(regs, ref);
  if (!NIL_P(txt)) {
    VALUE txt2 = rb_str_new2("");
    rb_str_cat_escaped_for_preformatted(txt2, RSTRING(txt)->ptr, RSTRING(txt)->ptr + RSTRING(txt)->len, opts);
    rb_hash_aset(regs, ref, txt2);
  }
  return rb_funcall(rb_formatter, meth, 1, regs);
}

VALUE
red_pass2(VALUE rb_formatter, VALUE regs, VALUE ref, VALUE btype, VALUE refs)
{
  btype = rb_hash_aref(regs, btype);
  StringValue(btype);
  return red_pass(rb_formatter, regs, ref, rb_intern(RSTRING(btype)->ptr), refs);
}

VALUE
red_block(VALUE rb_formatter, VALUE regs, VALUE block, VALUE refs)
{
  VALUE btype = rb_hash_aref(regs, ID2SYM(rb_intern("type")));
  block = rb_funcall(block, rb_intern("strip"), 0);
  if ((RSTRING(block)->len > 0) && !NIL_P(btype))
  {
    rb_hash_aset(regs, ID2SYM(rb_intern("text")), redcloth_inline2(rb_formatter, block, refs));
    block = rb_funcall(rb_formatter, rb_intern(RSTRING(btype)->ptr), 1, regs);
  }
  return block;
}

VALUE
red_blockcode(VALUE rb_formatter, VALUE regs, VALUE block)
{
  VALUE btype = rb_hash_aref(regs, ID2SYM(rb_intern("type")));
  block = rb_funcall(block, rb_intern("strip"), 0);
  if (RSTRING(block)->len > 0)
  {
    rb_hash_aset(regs, ID2SYM(rb_intern("text")), block);
    block = rb_funcall(rb_formatter, rb_intern(RSTRING(btype)->ptr), 1, regs);
  }
  return block;
}

void
red_inc(VALUE regs, VALUE ref)
{
  int aint = 0;
  VALUE aval = rb_hash_aref(regs, ref);
  if (aval != Qnil) aint = NUM2INT(aval);
  rb_hash_aset(regs, ref, INT2NUM(aint + 1));
}

VALUE
redcloth_inline(rb_formatter, p, pe, refs)
  VALUE rb_formatter;
  char *p, *pe;
  VALUE refs;
{
  int cs, act;
  char *ts, *te, *reg, *eof;
  VALUE block = rb_str_new2("");
  VALUE regs = Qnil;
  unsigned int opts = 0;
  
  VALUE options = rb_funcall(rb_formatter, rb_intern("options"), 0);
  Check_Type(options, T_HASH);
  if (rb_hash_aref(options, SYM_html_escape_entities) == Qtrue) opts |= SR_HTML_ESCAPE_ENTITIES;
  
  %% write init;

  %% write exec;

  return block;
}

/** Append characters to a string, escaping (&, <, >, ", ') to their html entities.
  * @param str ruby string
  * @param ts  start of character buffer to append
  * @param te  end of character buffer
  * @param opts integer with parsing options created by ORing. If SR_HTML_ESCAPE_ENTITIES is not set,
                escaping will not be performed.
  */
void
rb_str_cat_escaped(str, ts, te, opts)
  VALUE str;
  char *ts, *te;
  unsigned int opts;
{
  char *t = ts, *t2 = ts, *ch = NULL;
  if (te <= ts) return;

  while (t2 < te) {
    ch = NULL;
    if (opts & SR_HTML_ESCAPE_ENTITIES) {
      switch (*t2)
      {
        case '&':  ch = "&amp;";    break;
        case '>':  ch = "&gt;";     break;
        case '<':  ch = "&lt;";     break;
        case '"':  ch = "&quot;";   break;
        case '\n': ch = "<br />\n"; break;
        case '\'': ch = "&#8217;";  break;
      }
    }

    if (ch != NULL)
    {
      if (t2 > t)
        rb_str_cat(str, t, t2-t);
      rb_str_cat2(str, ch);
      t = t2 + 1;
    }

    t2++;
  }
  if (t2 > t)
    rb_str_cat(str, t, t2-t);
}

/** Append characters to a string, escaping (&, <, >) to their html entities.
  * @param str ruby string
  * @param ts  start of character buffer to append
  * @param te  end of character buffer
  * @param opts integer with parsing options created by ORing. If SR_HTML_ESCAPE_ENTITIES is not set,
                escaping will not be performed.
  */
void
rb_str_cat_escaped_for_preformatted(str, ts, te, opts)
  VALUE str;
  char *ts, *te;
  unsigned int opts;
{
  char *t = ts, *t2 = ts, *ch = NULL;
  if (te <= ts) return;

  while (t2 < te) {
    ch = NULL;
    if (opts & SR_HTML_ESCAPE_ENTITIES) {
      switch (*t2)
      {
        case '&':  ch = "&amp;";    break;
        case '>':  ch = "&gt;";     break;
        case '<':  ch = "&lt;";     break;
      }
    }

    if (ch != NULL)
    {
      if (t2 > t)
        rb_str_cat(str, t, t2-t);
      rb_str_cat2(str, ch);
      t = t2 + 1;
    }

    t2++;
  }
  if (t2 > t)
    rb_str_cat(str, t, t2-t);
}

VALUE
redcloth_inline2(formatter, str, refs)
  VALUE formatter, str, refs;
{
  StringValue(str);
  return redcloth_inline(formatter, RSTRING(str)->ptr, RSTRING(str)->ptr + RSTRING(str)->len + 1, refs);
}
