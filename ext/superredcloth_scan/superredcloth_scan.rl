/*
 * superredcloth_scan.rl
 *
 * $Author: why $
 * $Date$
 *
 * Copyright (C) 2007 why the lucky stiff
 */
#include <ruby.h>
#include "superredcloth.h"

static VALUE superredcloth_transform2(VALUE str, int top);
static VALUE super_ParseError, super_RedCloth;

#define INLINE(T)    rb_str_append(block, rb_funcall(super_RedCloth, rb_intern(#T), 1, regs))
#define BLOCK(T) \
  { \
    VALUE sblock = rb_funcall(block, rb_intern("strip"), 0); \
    if (RSTRING(sblock)->len > 0) \
    { \
      rb_str_append(html, rb_funcall(super_RedCloth, rb_intern(#T), 1, block)); \
    } \
    block = rb_str_new2(""); \
  }
#define FORMAT(A, T) \
  { \
    rb_hash_aset(regs, ID2SYM(rb_intern(#A)), superredcloth_transform2(rb_hash_aref(regs, ID2SYM(rb_intern(#A))), 1)); \
    rb_str_append(block, rb_funcall(super_RedCloth, rb_intern(#T), 1, regs)); \
  }
#define FORMAT_BLOCK(A, T) \
  { \
    /* rb_p(regs); */ \
    VALUE btype = rb_hash_aref(regs, ID2SYM(rb_intern(#T))); \
    rb_hash_aset(regs, ID2SYM(rb_intern(#A)), superredcloth_transform2(rb_hash_aref(regs, ID2SYM(rb_intern(#A))), 1)); \
    StringValue(btype); \
    rb_str_append(html, rb_funcall(super_RedCloth, rb_intern(RSTRING(btype)->ptr), 1, regs)); \
    block = rb_str_new2(""); \
  }
#define STORE(T)  \
  if (p > reg && reg >= tokstart) { \
    while (reg < p && ( *reg == '\r' || *reg == '\n' ) ) { reg++; } \
    while (p > reg && ( *(p - 1) == '\r' || *(p - 1) == '\n' ) ) { p--; } \
  } \
  if (p > reg && reg >= tokstart) { \
    VALUE str = rb_str_new(reg, p-reg); \
    rb_hash_aset(regs, ID2SYM(rb_intern(#T)), str); \
    /* printf("STORE(" #T ") %s\n", RSTRING(str)->ptr); */ \
  } else { \
    rb_hash_aset(regs, ID2SYM(rb_intern(#T)), Qnil); \
  }

%%{
  machine superredcloth_scan;

  action A { reg = p; }
  action X { regs = rb_hash_new(); reg = NULL; }
  action cat { 
    if (tokend > tokstart) {
      char *t = tokstart, *t2 = tokstart, *ch = NULL;
      while (t2 < tokend) {
        ch = NULL;
        switch (*t2)
        {
          case '&':  ch = "&amp;"; break;
          case '>':  ch = "&gt;"; break;
          case '<':  ch = "&lt;"; break;
          case '"':  ch = "&quot;"; break;
          case '\n': ch = "<br />\n"; break;
        }

        if (ch != NULL)
        {
          if (t2 > t)
            rb_str_cat(block, t, t2-t);
          rb_str_cat2(block, ch);
          t = t2 + 1;
        }

        t2++;
      }
      if (t2 > t)
        rb_str_cat(block, t, t2-t);
    }
  }
  action ignore { BLOCK(para); rb_str_append(html, rb_funcall(super_RedCloth, rb_intern("ignore"), 1, regs)); }

  # minor character groups
  CRLF = ( '\r'? '\n' ) ;
  A_HLGN = ( "<>" | "<" | ">" | "=" | [()]+ ) ;
  A_LIMIT = ( "<" | "=" | ">" ) ;
  A_VLGN = ( "-" | "^" | "~" ) ;
  C_CLAS = ( "(" [^)]+ >A %{ STORE(class) } ")" ) ;
  C_LNGE = ( "[" [^\]]+ >A %{ STORE(lang) } "]" ) ;
  C_STYL = ( "{" [^}]+ >A %{ STORE(style) } "}" ) ;
  S_CSPN = ( "\\" [0-9]+ ) ;
  S_RSPN = ( "/" [0-9]+ ) ;
  A = ( ( A_HLGN | A_VLGN )* ) >A %{ STORE(align) } ;
  A2 = ( A_LIMIT? ) >A %{ STORE(align) } ;
  S = ( S_CSPN S_RSPN  | S_RSPN S_CSPN? ) >A %{ STORE(span) } ;
  C = ( C_CLAS | C_STYL | C_LNGE )* ;
  PUNCT = ( "!" | '"' | "#" | "$" | "%" | "&" | "'" | "*" | "+" | "," | "-" | "." | "/" | ":" | ";" | "=" | "?" | "@" | "\\" | "^" | "_" | "`" | "|" | "~" ) ;
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
  scheme = ( alpha | digit | "+" | "-" | "." )* ;
  absolute_uri = (scheme ":" (uchar | reserved )*);
  path = (pchar+ ( "/" pchar* )*) ;
  query = ( uchar | reserved )* ;
  param = ( pchar | "/" )* ;
  params = (param ( ";" param )*) ;
  rel_path = (path? (";" params)?) ("?" query)?;
  absolute_path = ("/"+ rel_path);
  target = ("#" pchar*) ;
  uri = (target | absolute_uri target? | absolute_path target?) ;

  default = ^0 ;
  trailing = PUNCT - ("'" | '"') ;
  chars = (default - space)+ ;
  phrase = chars -- trailing ;
  EOF = 0 ;

  # common
  title = ( '(' [^)]+ ')' ) >A %{ STORE(title) } ;
  word = ( alnum | safe | " " ) ;

  # links
  link_says = ( word+ ) >A %{ STORE(name) } ;
  link_is = ( C dotspace? link_says title? ) ;
  link = ( '"' link_is '":' %A uri ) >X ;

  # images
  image_src = ( uri ) >A %{ STORE(src) } ;
  image_is = ( A2 C dotspace? image_src :> title? ) ;
  image_link = ( ":" uri ) ;
  image = ( "!" image_is "!" %A image_link? ) >X ;

  action T { STORE(text); }

  # footnotes
  footno = "[" >X %A digit+ %T "]" ;

  # markup
  mspace = ( ( " " | "\t" | CRLF )+ ) -- CRLF{2} ;
  mtext = ( chars (mspace chars)* ) ;
  code = "@" >X C mtext >A %T :> "@" ;
  strong = "*" >X C mtext >A %T :> "*" ;
  b = "**" >X C mtext >A %T :> "**" ;
  em = "_" >X C mtext >A %T :> "_" ;
  i = "__" >X C mtext >A %T :> "__" ;
  del = "-" >X C mtext >A %T :> "-" ;
  ins = "+" >X C mtext >A %T :> "+" ;
  sup = "^" >X C mtext >A %T :> "^" ;
  sub = "~" >X C mtext >A %T :> "~" ;
  span = "%" >X C mtext >A %T :> "%" ;
  cite = "??" >X C mtext >A %T :> "??" ;
  ignore = "==" >X %A mtext %T :> "==" ;
  quote1 = "'" >X %A mtext %T :> "'" ;
  quote2 = '"' >X %A mtext %T :> '"' ;
  apos = "'" ;
  notextile = "<notextile>" >X %A ( default+ ) %T :> "</notextile>" ;

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

  # blocks
  btext = ( ( default+ ) -- CRLF{2} ) ( CRLF{2} )? ;
  btype = ( "p" | "h1" | "h2" | "h3" | "h4" | "h5" | "h6" | "bq" ) >A %{ STORE(type) } ;
  block = ( btype A C ". " %A btext ) >X ;
  ftype = ( "fn" >A %{ STORE(type) } digit+ >A %{ STORE(id) } ) ;
  fblock = ( ftype A C ". " %A btext ) >X ;

  main := |*

    image { if ( *reg == ':') { reg += 1; STORE(href); } INLINE(image); };

    link { STORE(href); INLINE(link); };

    code { FORMAT(text, code); };
    strong { FORMAT(text, strong); };
    b { FORMAT(text, b); };
    em { FORMAT(text, em); };
    i { FORMAT(text, i); };
    del { FORMAT(text, del); };
    ins { FORMAT(text, ins); };
    sup { FORMAT(text, sup); };
    sub { FORMAT(text, sub); };
    span { FORMAT(text, span); };
    cite { FORMAT(text, cite); };
    ignore => ignore;
    quote1 { FORMAT(text, quote1); };
    quote2 { FORMAT(text, quote2); };
    notextile => ignore;

    ellipsis { INLINE(ellipsis); };
    emdash { INLINE(emdash); };
    endash { INLINE(endash); };
    arrow { INLINE(arrow); };
    acronym { INLINE(acronym); };
    dim { INLINE(dim); };
    trademark { INLINE(trademark); };
    registered { INLINE(registered); };
    copyright { INLINE(copyright); };

    footno { FORMAT(text, footno); };
    fblock { STORE(text); FORMAT_BLOCK(text, type); };

    block { STORE(text); FORMAT_BLOCK(text, type); };
    CRLF{2,} { BLOCK(para); };

    phrase => cat;
    PUNCT => cat;
    space => cat;

    EOF;

  *|;
}%%

%% write data nofinal;

static VALUE
superredcloth_transform(p, pe, top)
  char *p, *pe;
  int top;
{
  int cs, act;
  char *tokstart, *tokend, *reg;
  VALUE html = rb_str_new2("");
  VALUE block = rb_str_new2("");
  VALUE regs = Qnil;

  %% write init;

  %% write exec;

  if (RSTRING(block)->len > 0)
  {
    if (top == 1)
    {
      BLOCK(para);
    }
    else
    {
      rb_str_append(html, block);
    }
  }

  return html;
}

static VALUE
superredcloth_transform2(str, top)
  VALUE str;
  int top;
{
  StringValue(str);
  return superredcloth_transform(RSTRING(str)->ptr, RSTRING(str)->ptr + RSTRING(str)->len + 1, 0);
}

static VALUE
superredcloth_to_html(self)
  VALUE self;
{
  char *pe, *p;
  int len = 0;

  StringValue(self);
  return superredcloth_transform(RSTRING(self)->ptr, RSTRING(self)->ptr + RSTRING(self)->len + 1, 1);
}

void Init_superredcloth_scan()
{
  super_RedCloth = rb_define_class("SuperRedCloth", rb_cString);
  rb_define_method(super_RedCloth, "to_html", superredcloth_to_html, 0);
  super_ParseError = rb_define_class_under(super_RedCloth, "ParseError", rb_eException);
}
