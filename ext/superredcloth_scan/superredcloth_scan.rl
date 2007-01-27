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

VALUE super_ParseError, super_RedCloth;

%%{
  machine superredcloth_scan;

  action A { reg = p; }
  action X { regs = rb_hash_new(); reg = NULL; }
  action cat { rb_str_cat(block, tokstart, tokend-tokstart); }
  action notextile { BLOCK(para); rb_str_append(html, rb_funcall(super_RedCloth, rb_intern("ignore"), 1, regs)); }
  action T { STORE(text); }

  CRLF = ( '\r'? '\n' ) ;
  default = ^0 ;
  EOF = 0 ;

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
  N_CONT = "_" %{ ASET(start, continue) };
  N_NUM = digit+ >A %{ STORE(start) };
  N = ( N_CONT | N_NUM )? ;

  # blocks
  notextile = "<notextile>" >X %A ( default+ ) %T :> "</notextile>" ;
  para = ( default+ ) -- CRLF ;
  btext = para ( CRLF{2} )? ;
  btype = ( "p" | "h1" | "h2" | "h3" | "h4" | "h5" | "h6" | "bq" ) >A %{ STORE(type) } ;
  block = ( btype A C ". " %A btext ) >X ;
  ftype = ( "fn" >A %{ STORE(type) } digit+ >A %{ STORE(id) } ) ;
  fblock = ( ftype A C ". " %A btext ) >X ;
  ul = "*" %{ASET(type, ul)} ;
  ol = "#" %{ASET(type, ol)} ;
  listtext = btext -- (CRLF (ul | ol)) ;
  list = ( (ul | ol)+ N A C " " %A listtext ) >X ;

  main := |*

    notextile => notextile;
    fblock { STORE(text); FORMAT_BLOCK(text, type); };
    block { STORE(text); FORMAT_BLOCK(text, type); };
    list { STORE(text); FORMAT_BLOCK(text, type); };
    CRLF{2,} { BLOCK(para); };
    CRLF => cat;
    para => cat;

    EOF;

  *|;
}%%

%% write data nofinal;

VALUE
superredcloth_transform(p, pe)
  char *p, *pe;
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
    BLOCK(para);
  }

  return html;
}

VALUE
superredcloth_transform2(str)
  VALUE str;
{
  StringValue(str);
  return superredcloth_transform(RSTRING(str)->ptr, RSTRING(str)->ptr + RSTRING(str)->len + 1);
}

static VALUE
superredcloth_to_html(self)
  VALUE self;
{
  char *pe, *p;
  int len = 0;

  StringValue(self);
  return superredcloth_transform2(self);
}

void Init_superredcloth_scan()
{
  super_RedCloth = rb_define_class("SuperRedCloth", rb_cString);
  rb_define_method(super_RedCloth, "to_html", superredcloth_to_html, 0);
  super_ParseError = rb_define_class_under(super_RedCloth, "ParseError", rb_eException);
}
