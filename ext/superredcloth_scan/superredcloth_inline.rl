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

  action A { reg = p; }
  action X { regs = rb_hash_new(); reg = NULL; }
  action cat { rb_str_cat(block, tokstart, tokend-tokstart); }
  action esc { rb_str_cat_escaped(block, tokstart, tokend); }
  action ignore { rb_str_append(block, rb_funcall(super_RedCloth, rb_intern("ignore"), 1, regs)); }
  action T { STORE(text); }

  # minor character groups
  CRLF = ( '\r'? '\n' ) ;
  A_LEFT = "<" %{ ASET(align, left) } ;
  A_RIGHT = ">" %{ ASET(align, right) } ;
  A_JUSTIFIED = "<>" %{ ASET(align, justified) } ;
  A_CENTER = "=" %{ ASET(align, center) } ;
  A_PADLEFT = "(" >A %{ AINC(padding-left) } ;
  A_PADRIGHT = ")" >A %{ AINC(padding-right) } ;
  A_HLGN = ( A_LEFT | A_RIGHT | A_JUSTIFIED | A_CENTER | A_PADLEFT | A_PADRIGHT ) ;
  A_LIMIT = ( A_LEFT | A_CENTER | A_RIGHT ) ;
  A_VLGN = ( "-" %{ ASET(valign, middle) } | "^" %{ ASET(valign, top) } | "~" %{ ASET(valign, bottom) } ) ;
  C_CLAS = ( "(" ( [^)#]+ >A %{ STORE(class) } )? ("#" [^)]+ >A %{STORE(id)} )? ")" ) ;
  C_LNGE = ( "[" [^\]]+ >A %{ STORE(lang) } "]" ) ;
  C_STYL = ( "{" [^}]+ >A %{ STORE(style) } "}" ) ;
  S_CSPN = ( "\\" [0-9]+ ) ;
  S_RSPN = ( "/" [0-9]+ ) ;
  A = ( ( A_HLGN | A_VLGN )* ) ;
  A2 = ( A_LIMIT? ) ;
  S = ( S_CSPN S_RSPN  | S_RSPN S_CSPN? ) >A %{ STORE(span) } ;
  C = ( C_CLAS | C_STYL | C_LNGE )* ;
  PUNCT = ( "!" | '"' | "#" | "$" | "%" | "&" | "'" | "*" | "+" | "," | "--" | "." | "/" | ":" | ";" | "=" | "?" | "@" | "\\" | "^" | "_" | "`" | "|" | "~" | "[" | "(" | "<" ) ;
  dotspace = [. ] ;

  # URI tokens (lifted from Mongrel)
  CTL = (cntrl | 127);
  safe = ("$" | "-" | "_" | ".");
  extra = ("!" | "*" | "'" | "(" | ")" | ",");
  reserved = (";" | "/" | "?" | ":" | "@" | "&" | "=" | "+");
  unsafe = (CTL | " " | "\"" | "#" | "%" | "<" | ">");
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
  uri = (target | absolute_uri target? | absolute_path target? | rel_path target?) ;

  default = ^0 ;
  trailing = PUNCT - ("'" | '"') ;
  chars = (default - space)+ ;
  phrase = chars -- trailing ;
  EOF = 0 ;

  # html tags (from Hpricot)
  NameChar = [\-A-Za-z0-9._:?] ;
  Name = [A-Za-z_:] NameChar* ;
  NameAttr = NameChar+ ;
  Q1Attr = [^']* ;
  Q2Attr = [^"]* ;
  UnqAttr = ( space | [^ \t\n<>"'] [^ \t\n<>]* ) ;
  Nmtoken = NameChar+ ;
  Attr =  NameAttr space* "=" space* ('"' Q2Attr '"' | "'" Q1Attr "'" | UnqAttr space+ ) space* ;
  AttrEnd = ( NameAttr space* "=" space* UnqAttr? | Nmtoken ) ;
  AttrSet = ( Attr | Nmtoken space+ ) ;
  start_tag = "<" Name space+ AttrSet* (AttrEnd)? ">" | "<" Name ">";
  empty_tag = "<" Name space+ AttrSet* (AttrEnd)? "/>" | "<" Name "/>" ;
  end_tag = "</" Name space* ">" ;
  html_comment = "<!--" (default+) :> "-->";

  # common
  title = ( '(' [^)]+ >A %{ STORE(title) } ')' ) ;
  word = ( alnum | safe | " " ) ;
  mspace = ( ( " " | "\t" | CRLF )+ ) -- CRLF{2} ;
  mtext = ( chars (mspace chars)* ) ;

  # links
  link_says = ( mtext+ ) >A %{ STORE(name) } ;
  link = ( '"' C dotspace? link_says :> title? :> '":' %A uri ) >X ;

  # images
  image_src = ( uri ) >A %{ STORE(src) } ;
  image_is = ( A2 C dotspace? image_src :> title? ) ;
  image_link = ( ":" uri ) ;
  image = ( "!" image_is "!" %A image_link? ) >X ;

  # footnotes
  footno = "[" >X %A digit+ %T "]" ;

  # markup
  code = "@" >X C mtext >A %T :> "@" ;
  strong = "*" >X C mtext >A %T :> "*" ;
  b = "**" >X C mtext >A %T :> "**" ;
  em = "_" >X C mtext >A %T :> "_" ;
  i = "__" >X C mtext >A %T :> "__" ;
  del = " -" >X C ( mtext -- "-" ) >A %T :> "- " ;
  ins = "+" >X C mtext >A %T :> "+" ;
  sup = "^" >X C mtext >A %T :> "^" ;
  sub = "~" >X C mtext >A %T :> "~" ;
  span = "%" >X C mtext >A %T :> "%" ;
  cite = "??" >X C mtext >A %T :> "??" ;
  ignore = "==" >X %A mtext %T :> "==" ;
  snip = "```" >X %A mtext %T :> "```" ;
  quote1 = "'" >X %A mtext %T :> "'" ;
  quote2 = '"' >X %A mtext %T :> '"' ;

  # glyphs
  ellipsis = ( " "? >A %T "..." ) >X ;
  emdash = ( " "? "--" " "? ) >X ;
  arrow = ( " "? "->" " "? ) >X ;
  endash = ( " "? "-" " "? ) >X ;
  acronym = ( [A-Z] >A [A-Z0-9]{2,} %T "(" [^)]+ >A %{ STORE(title) } ")" ) >X ;
  dim = ( digit+ >A %{ STORE(x) } " x " digit+ >A %{ STORE(y) } ) >X ;
  tm = [Tt] [Mm] ;
  trademark = " "? ( "[" tm "]" | "(" tm ")" ) ;
  reg = [Rr] ;
  registered = " "? ( "[" reg "]" | "(" reg ")" ) ;
  cee = [Cc] ;
  copyright = " "? ( "[" cee "]" | "(" cee ")" ) ;

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
red_pass(VALUE regs, VALUE ref, ID meth)
{
  VALUE txt = rb_hash_aref(regs, ref);
  if (!NIL_P(txt)) rb_hash_aset(regs, ref, superredcloth_inline2(txt));
  return rb_funcall(super_RedCloth, meth, 1, regs);
}

VALUE
red_pass2(VALUE regs, VALUE ref, VALUE btype)
{
  btype = rb_hash_aref(regs, btype);
  StringValue(btype);
  return red_pass(regs, ref, rb_intern(RSTRING(btype)->ptr));
}

VALUE
red_block(VALUE block, ID meth)
{
  block = rb_funcall(block, rb_intern("strip"), 0);
  if (RSTRING(block)->len > 0)
  {
    block = rb_funcall(super_RedCloth, meth, 1, superredcloth_inline2(block));
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
superredcloth_inline(p, pe)
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
superredcloth_inline2(str)
  VALUE str;
{
  StringValue(str);
  return superredcloth_inline(RSTRING(str)->ptr, RSTRING(str)->ptr + RSTRING(str)->len + 1);
}
