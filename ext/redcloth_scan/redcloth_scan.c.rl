/*
 * redcloth_scan.c.rl
 *
 * Copyright (C) 2009 Jason Garber
 */
#define redcloth_scan_c

#include <ruby.h>
#include "redcloth.h"

VALUE mRedCloth, super_ParseError, super_RedCloth, super_HTML, super_LATEX;
int SYM_escape_preformatted, SYM_escape_attributes;

%%{

  machine redcloth_scan;
  include redcloth_common "redcloth_common.c.rl";

  action extend { extend = rb_hash_aref(regs, ID2SYM(rb_intern("type"))); }

  include redcloth_scan "redcloth_scan.rl";

}%%

%% write data nofinal;

VALUE
redcloth_transform(self, p, pe, refs)
  VALUE self;
  char *p, *pe;
  VALUE refs;
{
  char *orig_p = p, *orig_pe = pe;
  int cs, act, nest = 0;
  char *ts = NULL, *te = NULL, *reg = NULL, *bck = NULL, *eof = NULL;
  VALUE html = STR_NEW2("");
  VALUE table = STR_NEW2("");
  VALUE block = STR_NEW2("");
  VALUE regs; CLEAR_REGS()
  
  
  VALUE list_layout = Qnil;
  char *list_type = NULL;
  VALUE list_index = rb_ary_new();
  int list_continue = 0;
  VALUE plain_block; SET_PLAIN_BLOCK("p");
  VALUE extend = Qnil;
  char listm[10] = "";
  VALUE refs_found = rb_hash_new();
  
  %% write init;

  %% write exec;

  if (RSTRING_LEN(block) > 0)
  {
    ADD_BLOCK();
  }

  if ( NIL_P(refs) && rb_funcall(refs_found, rb_intern("empty?"), 0) == Qfalse ) {
    return redcloth_transform(self, orig_p, orig_pe, refs_found);
  } else {
    rb_funcall(self, rb_intern("after_transform"), 1, html);
    return html;
  }
}

VALUE
redcloth_transform2(self, str)
  VALUE self, str;
{
  StringValue(str);
  rb_funcall(self, rb_intern("before_transform"), 1, str);
  return redcloth_transform(self, RSTRING_PTR(str), RSTRING_PTR(str) + RSTRING_LEN(str) + 1, Qnil);
}

/*
 * Converts special characters into HTML entities.
 */
static VALUE
redcloth_html_esc(int argc, VALUE* argv, VALUE self) //(self, str, level)
{
  VALUE str, level;
  
  rb_scan_args(argc, argv, "11", &str, &level);
  
  VALUE new_str = STR_NEW2("");
  if (str == Qnil)
    return new_str;
    
  StringValue(str);
  
  if (RSTRING_LEN(str) == 0)
    return new_str;
  
  char *ts = RSTRING_PTR(str), *te = RSTRING_PTR(str) + RSTRING_LEN(str);
  char *t = ts, *t2 = ts, *ch = NULL;
  if (te <= ts) return Qnil;

  while (t2 < te) {
    ch = NULL;
    
    // normal + pre
    switch (*t2)
    {
      case '&':  ch = "amp";    break;
      case '>':  ch = "gt";     break;
      case '<':  ch = "lt";     break;
    }
    
    // normal (non-pre)
    if (level != SYM_escape_preformatted) {
      switch (*t2)
      {
        case '\n': ch = "br";     break;
        case '"' : ch = "quot";   break;
        case '\'': 
          ch = (level == SYM_escape_attributes) ? "apos" : "squot";
          break;
      }
    }
    
    if (ch != NULL)
    {
      if (t2 > t)
        rb_str_cat(new_str, t, t2-t);
      rb_str_concat(new_str, rb_funcall(self, rb_intern(ch), 1, rb_hash_new()));
      t = t2 + 1;
    }

    t2++;
  }
  if (t2 > t)
    rb_str_cat(new_str, t, t2-t);
  
  return new_str;
}

/*
 * Converts special characters into LaTeX entities.
 */
static VALUE
redcloth_latex_esc(VALUE self, VALUE str)
{  
  VALUE new_str = STR_NEW2("");
  
  if (str == Qnil)
    return new_str;
    
  StringValue(str);
  
  if (RSTRING_LEN(str) == 0)
    return new_str;
  
  char *ts = RSTRING_PTR(str), *te = RSTRING_PTR(str) + RSTRING_LEN(str);
  char *t = ts, *t2 = ts, *ch = NULL;
  if (te <= ts) return Qnil;

  while (t2 < te) {
    ch = NULL;
    
    switch (*t2) 
    { 
      case '{':  ch = "#123";   break;
      case '}':  ch = "#125";   break;
      case '\\': ch = "#92";    break;
      case '#':  ch = "#35";    break;
      case '$':  ch = "#36";    break;
      case '%':  ch = "#37";    break;
      case '&':  ch = "amp";    break;
      case '_':  ch = "#95";    break;
      case '^':  ch = "circ";   break;
      case '~':  ch = "tilde";  break;
      case '<':  ch = "lt";     break;
      case '>':  ch = "gt";     break;
      case '\n': ch = "#10";    break;
    }

    if (ch != NULL)
    {
      if (t2 > t)
        rb_str_cat(new_str, t, t2-t);
      VALUE opts = rb_hash_new();
      rb_hash_aset(opts, ID2SYM(rb_intern("text")), STR_NEW2(ch));
      rb_str_concat(new_str, rb_funcall(self, rb_intern("entity"), 1, opts));
      t = t2 + 1;
    }

    t2++;
  }
  if (t2 > t)
    rb_str_cat(new_str, t, t2-t);
  
  return new_str;
}

/*
 * Transforms a Textile document with +formatter+
 */
static VALUE
redcloth_to(self, formatter)
  VALUE self, formatter;
{
  rb_funcall(self, rb_intern("delete!"), 1, STR_NEW2("\r"));
  VALUE working_copy = rb_obj_clone(self);
  rb_extend_object(working_copy, formatter);
  
  if (rb_funcall(working_copy, rb_intern("lite_mode"), 0) == Qtrue) {
    return redcloth_inline2(working_copy, self, rb_hash_new());
  } else {
    return redcloth_transform2(working_copy, self);
  }
}

void Init_redcloth_scan()
{
  mRedCloth = rb_define_module("RedCloth");
  /* A Textile document that can be converted to other formats. See
   the README for Textile syntax. */
  super_RedCloth = rb_define_class_under(mRedCloth, "TextileDoc", rb_cString);
  rb_define_method(super_RedCloth, "to", redcloth_to, 1);
  super_ParseError = rb_define_class_under(super_RedCloth, "ParseError", rb_eException);
  /* Escaping */
  rb_define_method(super_RedCloth, "html_esc", redcloth_html_esc, -1);
  rb_define_method(super_RedCloth, "latex_esc", redcloth_latex_esc, 1);
  SYM_escape_preformatted   = ID2SYM(rb_intern("html_escape_preformatted"));
  SYM_escape_attributes     = ID2SYM(rb_intern("html_escape_attributes"));
}