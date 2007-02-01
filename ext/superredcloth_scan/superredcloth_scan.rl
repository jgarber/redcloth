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
  include superredcloth_common "superredcloth_common.rl";

  action notextile { rb_str_append(html, rb_funcall(super_RedCloth, rb_intern("ignore"), 1, regs)); }
  action lists {
    char listm[10] = "";
    if (nest > RARRAY(list_layout)->len)
    {
      sprintf(listm, "%s_open", list_type);
      rb_str_append(list, rb_funcall(super_RedCloth, rb_intern(listm), 1, regs));
      rb_ary_store(list_layout, nest-1, rb_str_new2(list_type));
    }
    while (nest < RARRAY(list_layout)->len)
    {
      VALUE end_list = rb_ary_pop(list_layout);
      if (!NIL_P(end_list))
      {
        StringValue(end_list);
        sprintf(listm, "%s_close", RSTRING(end_list)->ptr);
        rb_str_append(list, rb_funcall(super_RedCloth, rb_intern(listm), 1, regs));
      }
    }

    if (nest == 0)
    {
      rb_str_append(html, list);
      list = rb_str_new2("");
    }

    regs = rb_hash_new();
  }

  # blocks
  notextile = ( "<notextile>" >X %A default+ %T :> "</notextile>" ) >{ BLOCK(para); } ;
  para = ( default+ ) -- CRLF ;
  btext = para ( CRLF{2} )? ;
  btype = ( "p" | "h1" | "h2" | "h3" | "h4" | "h5" | "h6" | "bq" ) >A %{ STORE(type) } ;
  block = ( btype A C :> dotspace %A btext ) >X ;
  ftype = ( "fn" >A %{ STORE(type) } digit+ >A %{ STORE(id) } ) ;
  fblock = ( ftype A C :> dotspace %A btext ) >X ;
  ul = "*" %{nest++; list_type = "ul";};
  ol = "#" %{nest++; list_type = "ol";};
  listtext = ( default+ ) -- (CRLF (ul | ol | CRLF));
  list = ( (ul | ol)+ N %lists A C :> " " %A listtext ) >X %{ nest = 0; STORE(text); PASS(list, text, li); } ;
  lists = (list (CRLF list)* ) >{ BLOCK(para); nest = 0; list = rb_str_new2(""); list_layout = rb_ary_new(); };

  # tables
  tddef = ( S A C :> dotspace ) ;
  td = ( tddef? btext >A %T :> "|" >{PASS(table, text, td);} ) >X ;
  trdef = ( A C :> dotspace ) ;
  tr = ( trdef? "|" %{INLINE(table, tr_open);} td+ ) >X %{INLINE(table, tr_close);} ;
  trows = ( tr (CRLF >X tr)* ) ;
  tdef = ( "table" >X A C :> dotspace CRLF ) ;
  table = ( tdef? trows >{INLINE(table, table_open);} CRLF? ) >{ BLOCK(para); regs = rb_hash_new(); reg = NULL; } ;

  main := |*

    notextile => notextile;
    fblock { STORE(text); PASS2(html, text, type); };
    block { STORE(text); PASS2(html, text, type); };
    lists => lists;
    table { INLINE(table, tr_close); INLINE(table, table_close); DONE(table); };
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
  int cs, act, nest;
  char *tokstart, *tokend, *reg;
  VALUE html = rb_str_new2("");
  VALUE block = rb_str_new2("");
  VALUE table = rb_str_new2("");
  VALUE regs = Qnil;
  VALUE list = Qnil, list_layout = Qnil;
  char *list_type = NULL;

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
  rb_str_cat2(str, "\n");
  StringValue(str);
  return superredcloth_transform(RSTRING(str)->ptr, RSTRING(str)->ptr + RSTRING(str)->len + 1);
}

static VALUE
superredcloth_to_html(self)
  VALUE self;
{
  char *pe, *p;
  int len = 0;

  return superredcloth_transform2(self);
}

void Init_superredcloth_scan()
{
  super_RedCloth = rb_define_class("SuperRedCloth", rb_cString);
  rb_define_method(super_RedCloth, "to_html", superredcloth_to_html, 0);
  super_ParseError = rb_define_class_under(super_RedCloth, "ParseError", rb_eException);
}
