/*
 * superredcloth_inline.rl
 *
 * $Author: why $
 * $Date$
 *
 * Copyright (C) 2007 why the lucky stiff
 */
#include <ruby.h>
#include "superredcloth.h"

%%{

  machine superredcloth_inline;
  include superredcloth_common "superredcloth_common.rl";

  # URI tokens (lifted from Mongrel)
  CTL = (cntrl | 127);
  safe = ("$" | "-" | "_" | ".");
  extra = ("!" | "*" | "'" | "(" | ")" | "," | "#");
  reserved = (";" | "/" | "?" | ":" | "@" | "&" | "=" | "+");
  unsafe = (CTL | " " | "\"" | "%" | "<" | ">");
  national = any -- (alpha | digit | reserved | extra | safe | unsafe);
  unreserved = (alpha | digit | safe | extra | national);
  escape = ("%" xdigit xdigit);
  uchar = (unreserved | escape);
  pchar = (uchar | ":" | "@" | "&" | "=" | "+");
  scheme = ( alpha | digit | "+" | "-" | "." )+ ;
  absolute_uri = (scheme ":" (uchar | reserved )*);
  safepath = (pchar* (alpha | digit | safe) pchar*) ;
  path = (safepath ( "/" pchar* )*) ;
  query = ( uchar | reserved )* ;
  param = ( pchar | "/" )* ;
  params = (param ( ";" param )*) ;
  rel_path = (path (";" params)?) ("?" query)?;
  absolute_path = ("/"+ rel_path?);
  target = ("#" pchar*) ;
  uri = (target | absolute_uri | absolute_path | rel_path) ;

  # common
  title = ( '(' default+ >A %{ STORE(title) } :> ')' ) ;
  word = ( alnum | safe | " " ) ;
  mspace = ( ( " " | "\t" | CRLF )+ ) -- CRLF{2} ;
  mtext = ( chars (mspace chars)* ) ;

  # links
  link_says = ( mtext+ ) >A %{ STORE(name) } ;
  link = ( '"' C "."* " "* link_says :> title? :> '":' %A uri ) >X ;

  # images
  image_src = ( uri ) >A %{ STORE(src) } ;
  image_is = ( A2 C "."* " "* image_src :> title? ) ;
  image_link = ( ":" uri ) ;
  image = ( "!" image_is "!" %A image_link? ) >X ;

  # footnotes
  footno = "[" >X %A digit+ %T "]" ;

  # markup
  code = "["? "@" >X C mtext >A %T :> "@" "]"? ;
  strong = "["? "*" >X C mtext >A %T :> "*" "]"? ;
  b = "["? "**" >X C mtext >A %T :> "**" "]"? ;
  em = "["? "_" >X C mtext >A %T :> "_" "]"? ;
  i = "["? "__" >X C mtext >A %T :> "__" "]"? ;
  del = (" "|"[") "-" >X C ( mtext -- "-" ) >A %T :> "-" (" "|"]") ;
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
  emdash = ( " "? "--" " "? ) >X ;
  arrow = ( " "? "->" " "? ) >X ;
  endash = ( " "? "-" " "? ) >X ;
  acronym = ( [A-Z] >A [A-Z0-9]{2,} %T "(" default+ >A %{ STORE(title) } :> ")" ) >X ;
  dim = ( digit+ >A %{ STORE(x) } " x " digit+ >A %{ STORE(y) } ) >X ;
  tm = [Tt] [Mm] ;
  trademark = " "? ( "[" tm "]" | "(" tm ")" ) ;
  reg = [Rr] ;
  registered = " "? ( "[" reg "]" | "(" reg ")" ) ;
  cee = [Cc] ;
  copyright = " "? ( "[" cee "]" | "(" cee ")" ) ;
  entity = ( "&" %A ( '#' digit+ | alpha+ ) %T ';' ) >X ;

  main := |*

    image { if ( *reg == ':') { reg += 1; STORE_URL(href); } INLINE(block, image); };

    link { STORE_URL(href); PASS(block, name, link); };

    code { PASS(block, text, code); };
    strong { PASS(block, text, strong); };
    b { PASS(block, text, b); };
    em { PASS(block, text, em); };
    i { PASS(block, text, i); };
    del { PASS(block, text, del); };
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
    acronym { INLINE(block, acronym); };
    dim { INLINE(block, dim); };
    trademark { INLINE(block, trademark); };
    registered { INLINE(block, registered); };
    copyright { INLINE(block, copyright); };
    footno { PASS(block, text, footno); };
    entity { INLINE(block, entity); };

    start_tag => cat;
    end_tag => cat;
    empty_tag => cat;
    html_comment => cat;

    phrase => esc;
    PUNCT => esc;
    space => esc;

    EOF;

  *|;

}%%

%% write data nofinal;

VALUE
red_pass(VALUE rb_formatter, VALUE regs, VALUE ref, ID meth)
{
  VALUE txt = rb_hash_aref(regs, ref);
  if (!NIL_P(txt)) rb_hash_aset(regs, ref, superredcloth_inline2(rb_formatter, txt));
  return rb_funcall(rb_formatter, meth, 1, regs);
}

VALUE
red_pass2(VALUE rb_formatter, VALUE regs, VALUE ref, VALUE btype)
{
  btype = rb_hash_aref(regs, btype);
  StringValue(btype);
  return red_pass(rb_formatter, regs, ref, rb_intern(RSTRING(btype)->ptr));
}

VALUE
red_block(VALUE rb_formatter, VALUE regs, VALUE block)
{
  VALUE btype = rb_hash_aref(regs, ID2SYM(rb_intern("type")));
  block = rb_funcall(block, rb_intern("strip"), 0);
  if (RSTRING(block)->len > 0)
  {
    rb_hash_aset(regs, ID2SYM(rb_intern("text")), superredcloth_inline2(rb_formatter, block));
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
superredcloth_inline(rb_formatter, p, pe)
  VALUE rb_formatter;
  char *p, *pe;
{
  int cs, act;
  char *tokstart, *tokend, *reg;
  VALUE block = rb_str_new2("");
  VALUE regs = Qnil;

  %% write init;

  %% write exec;

  return block;
}

void
rb_str_cat_escaped(str, tokstart, tokend)
  VALUE str;
  char *tokstart, *tokend;
{
  char *t = tokstart, *t2 = tokstart, *ch = NULL;
  if (tokend <= tokstart) return;

  while (t2 < tokend) {
    ch = NULL;
    switch (*t2)
    {
      case '&':  ch = "&amp;";    break;
      case '>':  ch = "&gt;";     break;
      case '<':  ch = "&lt;";     break;
      case '"':  ch = "&quot;";   break;
      case '\n': ch = "<br />\n"; break;
      case '\'': ch = "&#8217;";  break;
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
superredcloth_inline2(formatter, str)
  VALUE formatter, str;
{
  StringValue(str);
  return superredcloth_inline(formatter, RSTRING(str)->ptr, RSTRING(str)->ptr + RSTRING(str)->len + 1);
}
